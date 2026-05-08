import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/analysis_result.dart';
import '../services/ad_service.dart';
import '../services/share_card_content.dart';
import '../viewmodels/analysis_viewmodel.dart';

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final _shareCardKey = GlobalKey();
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AnalysisViewModel>();
      vm.addListener(_onVmChanged);
      _maybeShowAd(vm);
    });
  }

  @override
  void dispose() {
    context.read<AnalysisViewModel>().removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() => _maybeShowAd(context.read<AnalysisViewModel>());

  void _maybeShowAd(AnalysisViewModel vm) {
    if (!vm.awaitingAdBeforeResult || _adShown) return;
    _adShown = true;
    AdService().showRewardedAd(onComplete: () {
      if (mounted) vm.revealResult();
    });
  }

  // 공유 카드 전체를 PNG로 캡처
  Future<Uint8List?> _captureCard() async {
    try {
      // 한 프레임 대기해서 off-screen 위젯이 렌더링되도록 함
      await Future.delayed(const Duration(milliseconds: 80));
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareAsImage(BuildContext ctx) async {
    final l10n = AppLocalizations.of(ctx);
    final bytes = await _captureCard();
    if (bytes == null) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.shareError)),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/aipic_share.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _saveAsImage(BuildContext ctx) async {
    final l10n = AppLocalizations.of(ctx);
    final bytes = await _captureCard();
    if (bytes == null) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.saveError)),
        );
      }
      return;
    }
    try {
      await Gal.putImageBytes(bytes, album: 'A.I Room Roast');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.savedToGallery)),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.saveToGalleryFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalysisViewModel>();
    final result = vm.result;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).analysisResult),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            vm.reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ── 메인 화면 + 하단 배너 ──
            Column(
              children: [
                Expanded(
                  child: vm.state == AnalysisState.error
                      ? _ErrorView(
                          message: vm.errorMessage,
                          onRetry: () => vm.analyzeImage(),
                          onBack: () {
                            vm.reset();
                            Navigator.of(context).pop();
                          },
                        )
                      : result == null
                          ? _StreamingView(
                              text: vm.streamedText,
                              imageBytes: vm.imageBytes,
                              steps: AppLocalizations.of(context).streamingSteps,
                              drips: AppLocalizations.of(context).streamingDrips,
                            )
                          : _ResultBody(
                              result: result,
                              imageBytes: vm.imageBytes,
                              onShare: () => _shareAsImage(context),
                              onSave: () => _saveAsImage(context),
                            ),
                ),
                if (result != null) const BannerAdWidget(),
              ],
            ),

            // ── 공유용 카드: 거의 투명하게(opacity 0.01) 렌더링 유지 ──
            // opacity=0 이면 Flutter가 paint 자체를 skip해서 toImage() 불가.
            // opacity=0.01 → alpha=3, 육안 식별 불가하지만 paint는 수행됨.
            if (result != null)
              IgnorePointer(
                child: Opacity(
                  opacity: 0.01,
                  child: SizedBox(
                    width: 0,
                    height: 0,
                    child: OverflowBox(
                      minWidth: screenWidth,
                      maxWidth: screenWidth,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      alignment: Alignment.topLeft,
                      child: RepaintBoundary(
                        key: _shareCardKey,
                        child: ShareCard(result: result, imageBytes: vm.imageBytes),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 스트리밍 뷰 (스캔 연출 + 단계 + 가짜 진행률 + 드립) ────

class _StreamingView extends StatefulWidget {
  final String text;
  final Uint8List? imageBytes;
  final List<String> steps;
  final List<String> drips;
  const _StreamingView({
    required this.text,
    this.imageBytes,
    required this.steps,
    required this.drips,
  });

  @override
  State<_StreamingView> createState() => _StreamingViewState();
}

class _StreamingViewState extends State<_StreamingView>
    with TickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late AnimationController _scanCtrl;
  late Animation<Color?> _colorAnim;


  int _stepIndex = 0;
  int _dripIndex = -1;
  int _percentStage = 0;
  late List<int> _fakePercents;
  Timer? _timer;

  /// 10단계 랜덤 진행률 생성 (항상 올라감, 3초×10 = 30초, 마지막은 95~98)
  static List<int> _generatePercents() {
    final rng = math.Random();
    return [
      5  + rng.nextInt(6),   // 5~10
      14 + rng.nextInt(6),   // 14~19
      24 + rng.nextInt(6),   // 24~29
      36 + rng.nextInt(6),   // 36~41
      48 + rng.nextInt(6),   // 48~53
      60 + rng.nextInt(6),   // 60~65
      70 + rng.nextInt(6),   // 70~75
      80 + rng.nextInt(6),   // 80~85
      89 + rng.nextInt(5),   // 89~93
      95 + rng.nextInt(4),   // 95~98
    ];
  }

  @override
  void initState() {
    super.initState();
    _fakePercents = _generatePercents();
    _spinCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _scanCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _colorAnim = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF6C63FF), end: const Color(0xFFFF6584)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFFFF6584), end: const Color(0xFF43CFAC)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF43CFAC), end: const Color(0xFF6C63FF)),
          weight: 1),
    ]).animate(_spinCtrl);

    _timer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (!mounted) return;
      setState(() {
        _stepIndex = (_stepIndex + 1) % widget.steps.length;
        if (_dripIndex == -1) {
          _dripIndex = 0;
        } else {
          _dripIndex = (_dripIndex + 1) % widget.drips.length;
        }
        if (_percentStage < _fakePercents.length - 1) {
          _percentStage++;
        }
      });
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _scanCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = _fakePercents[_percentStage];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── 이미지 + 스캔 오버레이 ──
          if (widget.imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(widget.imageBytes!, fit: BoxFit.cover),
                    // 스캔 라인 애니메이션
                    AnimatedBuilder(
                      animation: _scanCtrl,
                      builder: (_, child) => Positioned(
                        top: _scanCtrl.value * 200,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C63FF).withAlpha(0),
                                const Color(0xFF6C63FF).withAlpha(200),
                                const Color(0xFF74B9FF).withAlpha(200),
                                const Color(0xFF74B9FF).withAlpha(0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF6C63FF).withAlpha(120),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 반투명 오버레이
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(60),
                      ),
                    ),
                    // 중앙 퍼센트
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              '$percent%',
                              key: ValueKey(percent),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).analyzing,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ── 진행바 ──
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              height: 8,
              child: LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: theme.colorScheme.primary.withAlpha(30),
                valueColor: AlwaysStoppedAnimation(_colorAnim.value),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── 단계 텍스트 ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              widget.steps[_stepIndex],
              key: ValueKey(_stepIndex),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),

          // ── 스텝 인디케이터 점 ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.steps.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _stepIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _stepIndex
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withAlpha(60),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          // ── 한 줄 드립 ──
          if (_dripIndex >= 0) ...[
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_dripIndex),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.drips[_dripIndex],
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── 에러 뷰 ────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: Color(0xFF6C5CE7)),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).analysisFailed,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message.isNotEmpty
                  ? message
                  : AppLocalizations.of(context).unknownError,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppLocalizations.of(context).retryAnalysis),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: Text(AppLocalizations.of(context).reselectPhoto),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 결과 본문 ──────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final AnalysisResult result;
  final Uint8List? imageBytes;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _ResultBody({
    required this.result,
    this.imageBytes,
    required this.onShare,
    required this.onSave,
  });

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // 점수 범위별 이모지
  String _statusEmoji(double score) {
    if (score >= 0.9) return '🤩';
    if (score >= 0.8) return '😊';
    if (score >= 0.6) return '😌';
    if (score >= 0.4) return '🤔';
    return '😬';
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = _parseColor(result.statusColorCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                imageBytes!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

          if (imageBytes != null) const SizedBox(height: 16),

          Center(
            child: _AnimatedScoreGauge(
                score: result.stateScore, color: statusColor),
          ),
          const SizedBox(height: 8),

          Center(
            child: Text(
              result.targetName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Text(
                  _statusEmoji(result.stateScore),
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.statusMessage(result.stateScore),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

          // ── AI 한줄 요약 ──
          if (result.summary.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(40),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(30),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.summary,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms),
          ],

          // ── 한줄 디스 ──
          if (result.oneLineDis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.deepOrange.withAlpha(120),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withAlpha(60),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI FACT 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '🔥 AI FACT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  // 본문
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.stateScore >= 0.8
                              ? '😏'
                              : result.stateScore >= 0.5
                                  ? '😬'
                                  : '💀',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            result.oneLineDis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A2800),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.05, end: 0),
          ],

          const SizedBox(height: 20),

          _CollapsibleSectionCard(
            title: l10n.detailedDescription,
            icon: Icons.description_outlined,
            child: Text(
              result.detailedDescription,
              style: theme.textTheme.bodyMedium,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          _SectionCard(
            title: l10n.keyFeatures,
            icon: Icons.emoji_events_outlined,
            child: _BadgeCharacteristics(
              characteristics: result.keyCharacteristics,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // ── 추천 조치 + AD (광고 시청 후 잠금 해제) ──
          _AdGatedRecommendationsCard(result: result)
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: _PrimaryShareButton(
                  icon: Icons.share_rounded,
                  label: l10n.shareQuestion,
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: _SecondaryButton(
                  icon: Icons.save_alt_rounded,
                  label: l10n.saveResult,
                  onTap: onSave,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── 애니메이션 스코어 게이지 ────────────────────────────────

class _AnimatedScoreGauge extends StatefulWidget {
  final double score;
  final Color color;
  const _AnimatedScoreGauge({required this.score, required this.color});

  @override
  State<_AnimatedScoreGauge> createState() => _AnimatedScoreGaugeState();
}

class _AnimatedScoreGaugeState extends State<_AnimatedScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: _GradientGaugePainter(
                  score: _animation.value,
                  color: widget.color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_animation.value * 100).round()}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.color.withAlpha(178),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── 그라데이션 게이지 페인터 ────────────────────────────────

class _GradientGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GradientGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 12.0;
    const startAngle = math.pi * 0.75;
    const sweepFull = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = color.withAlpha(38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      trackPaint,
    );

    if (score > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: 0,
        endAngle: sweepFull,
        colors: const [
          Color(0xFFF44336),
          Color(0xFFFF9800),
          Color(0xFFFFEB3B),
          Color(0xFF4CAF50),
        ],
        stops: const [0.0, 0.33, 0.66, 1.0],
        transform: GradientRotation(startAngle),
      );

      final valuePaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle,
        sweepFull * score,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GradientGaugePainter old) =>
      old.score != score || old.color != color;
}

// ─── 배지 스타일 특징 ────────────────────────────────────────

class _BadgeCharacteristics extends StatelessWidget {
  final List<String> characteristics;

  const _BadgeCharacteristics({required this.characteristics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: characteristics
          .map((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primaryContainer.withAlpha(180),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(40),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏅', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ─── 업그레이드 체크리스트 아이템 ────────────────────────────

class _UpgradeChecklistItem extends StatelessWidget {
  final String text;
  final int scoreBoost;
  final bool checked;
  final VoidCallback onChanged;

  const _UpgradeChecklistItem({
    required this.text,
    required this.scoreBoost,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    checked ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: checked
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  decoration: checked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 점수 상승 배지
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: checked
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFF4CAF50).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppLocalizations.of(context).scoreBoostLabel(scoreBoost),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: checked
                      ? theme.colorScheme.onSurfaceVariant
                      : const Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 완료율 배지 ────────────────────────────────────────────

class _CompletionBadge extends StatelessWidget {
  final double rate;
  const _CompletionBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (rate * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: rate >= 1.0
            ? const Color(0xFF4CAF50).withAlpha(25)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppLocalizations.of(context).completionPercent(percent),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: rate >= 1.0
              ? const Color(0xFF4CAF50)
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── 섹션 카드 ──────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── 접기/펼치기 섹션 카드 ───────────────────────────────────

class _CollapsibleSectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _CollapsibleSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  State<_CollapsibleSectionCard> createState() =>
      _CollapsibleSectionCardState();
}

class _CollapsibleSectionCardState extends State<_CollapsibleSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: widget.child,
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              if (!_expanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    AppLocalizations.of(context).seeMore,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 추천 조치 + AD (광고 게이트) ───────────────────────────

class _AdGatedRecommendationsCard extends StatefulWidget {
  final AnalysisResult result;
  const _AdGatedRecommendationsCard({required this.result});

  @override
  State<_AdGatedRecommendationsCard> createState() =>
      _AdGatedRecommendationsCardState();
}

class _AdGatedRecommendationsCardState
    extends State<_AdGatedRecommendationsCard> {
  bool _unlocked = false;
  bool _loading = false;

  void _unlock() {
    if (_unlocked || _loading) return;
    setState(() => _loading = true);
    AdService().showRewardedAd(
      onComplete: () {
        if (mounted) setState(() { _unlocked = true; _loading = false; });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<AnalysisViewModel>();
    final result = widget.result;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
             
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).unlockHiddenResult,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (_unlocked) ...[
                const Spacer(),
                _CompletionBadge(rate: vm.completionRate),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (!_unlocked)
            InkWell(
              onTap: _loading ? null : _unlock,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(30)),
                ),
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Column(
                        children: [
                          const Text('📺',
                              style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 6),
                          Text(
                            AppLocalizations.of(context).notSatisfied,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context).watchToUnlock,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            )
          else
            Column(
              children: result.recommendations
                  .asMap()
                  .entries
                  .map((e) => _UpgradeChecklistItem(
                        text: e.value,
                        scoreBoost:
                            e.key < result.recommendationScores.length
                                ? result.recommendationScores[e.key]
                                : 3,
                        checked:
                            vm.checkedRecommendations.length > e.key
                                ? vm.checkedRecommendations[e.key]
                                : false,
                        onChanged: () => vm.toggleRecommendation(e.key),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ─── 메인 공유 버튼 (그라데이션) ────────────────────────────

class _PrimaryShareButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryShareButton> createState() => _PrimaryShareButtonState();
}

class _PrimaryShareButtonState extends State<_PrimaryShareButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withAlpha(70),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 보조 저장 버튼 (outline + 연한 배경) ───────────────────

class _SecondaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(50),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

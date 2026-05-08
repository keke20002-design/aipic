import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/ad_service.dart';
import '../viewmodels/analysis_viewmodel.dart';
import 'history_view.dart';
import 'result_view.dart';

const _kPurple = Color(0xFF6C5CE7);
const _kSky = Color(0xFF74B9FF);

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
    AnalysisViewModel vm,
  ) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (xfile != null) {
      await vm.setImage(xfile);
    }
  }

  void _showPickerSheet(BuildContext context, AnalysisViewModel vm) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: _kPurple),
                title: Text(l10n.cameraCapture),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(context, ImageSource.camera, vm);
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: _kPurple),
                title: Text(l10n.gallerySelect),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(context, ImageSource.gallery, vm);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalysisViewModel>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const SafeArea(
        top: false,
        child: BannerAdWidget(),
      ),
      appBar: AppBar(
        title: _LocaleTitle(),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryView()),
            ),
            child: Text(
              l10n.historyView,
              style: const TextStyle(
                color: _kPurple,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0EDFF), Color(0xFFE4F0FF), Color(0xFFEEF8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ImageCard(
                    imageBytes: vm.imageBytes,
                    onTap: vm.isLoading
                        ? null
                        : () => _showPickerSheet(context, vm),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
                ),

                const SizedBox(height: 6),

                Center(
                  child: Text(
                    l10n.tagline,
                    style: TextStyle(
                      fontSize: 12,
                      color: _kPurple.withAlpha(160),
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _PrimaryPickButton(
                        icon: Icons.camera_alt_rounded,
                        label: l10n.takeNow,
                        onTap: vm.isLoading
                            ? null
                            : () => _pickImage(context, ImageSource.camera, vm),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _SecondaryPickButton(
                        icon: Icons.photo_library_outlined,
                        label: l10n.pickFromGallery,
                        onTap: vm.isLoading
                            ? null
                            : () => _pickImage(context, ImageSource.gallery, vm),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 10),

                const _PreviewSection()
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 10),

                if (vm.state == AnalysisState.error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      vm.errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                _GradientAnalyzeButton(
                  enabled: vm.selectedImage != null && !vm.isLoading,
                  isLoading: vm.isLoading,
                  onTap: () {
                    if (!context.mounted) return;
                    vm.analyzeImage(languageCode: locale.languageCode);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: vm,
                          child: const ResultView(),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 사진 카드 ───────────────────────────────────────────────

class _ImageCard extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback? onTap;
  const _ImageCard({this.imageBytes, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (imageBytes != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _kPurple.withAlpha(40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _kPurple.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPurple, _kSky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 38,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.warningTitle,
              style: const TextStyle(
                color: _kPurple,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.scanStart,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 카메라 메인 버튼 ────────────────────────────────────────

class _PrimaryPickButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PrimaryPickButton(
      {required this.icon, required this.label, this.onTap});

  @override
  State<_PrimaryPickButton> createState() => _PrimaryPickButtonState();
}

class _PrimaryPickButtonState extends State<_PrimaryPickButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [_kPurple, _kSky],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _kPurple.withAlpha(70),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 18, color: enabled ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 갤러리 보조 버튼 ────────────────────────────────────────

class _SecondaryPickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SecondaryPickButton(
      {required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: _kPurple),
      label: Text(label, style: const TextStyle(color: _kPurple)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: _kPurple, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── 티저 + 예시 카드 ────────────────────────────────────────

class _PreviewSection extends StatelessWidget {
  const _PreviewSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quotes = l10n.previewQuotes;
    final quote = quotes[Random().nextInt(quotes.length)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            l10n.teaser,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kPurple.withAlpha(200),
              letterSpacing: 0.2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kPurple.withAlpha(30), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withAlpha(15),
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
                  const Text('📊', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.analysisExample,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _kPurple,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kPurple.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'SAMPLE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _kPurple.withAlpha(160),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _ScoreRow(
                  label: l10n.cleanlinessLabel,
                  score: 82,
                  scoreUnit: l10n.scoreUnit,
                  color: const Color(0xFF4CAF50)),
              const SizedBox(height: 6),
              _ScoreRow(
                  label: l10n.organizationLabel,
                  score: 65,
                  scoreUnit: l10n.scoreUnit,
                  color: const Color(0xFFFF9800)),

              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        quote,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF7B5E00),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final String scoreUnit;
  final Color color;
  const _ScoreRow(
      {required this.label,
      required this.score,
      required this.scoreUnit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score$scoreUnit',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── 분석 시작 그라데이션 버튼 ──────────────────────────────

class _GradientAnalyzeButton extends StatefulWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;
  const _GradientAnalyzeButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_GradientAnalyzeButton> createState() =>
      _GradientAnalyzeButtonState();
}

class _GradientAnalyzeButtonState extends State<_GradientAnalyzeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTapDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp:
          widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel:
          widget.enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [_kPurple, _kSky],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.enabled ? null : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: _kPurple.withAlpha(90),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.enabled
                        ? l10n.analyzeStartEnabled
                        : l10n.analyzeStartDisabled,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.enabled
                          ? Colors.white
                          : Colors.grey.shade400,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── 언어별 타이틀 이미지 ────────────────────────────────────────

class _LocaleTitle extends StatelessWidget {
  static String _titleAsset(String langCode) {
    switch (langCode) {
      case 'en':
        return 'assets/title_en.png';
      case 'ja':
        return 'assets/title_ja.png';
      case 'vi':
        return 'assets/title_vi.png';
      default:
        return 'assets/title.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Image.asset(
      _titleAsset(lang),
      height: 55,
      fit: BoxFit.contain,
    );
  }
}

// ─── [TEST] 언어 전환 버튼 ─────────────────────────────────────

class _LangPickerButton extends StatelessWidget {
  static const _langs = [
    ('🇰🇷', '한국어', 'ko'),
    ('🇺🇸', 'English', 'en'),
    ('🇯🇵', '日本語', 'ja'),
    ('🇻🇳', 'Tiếng Việt', 'vi'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    final currentFlag = _langs
        .firstWhere((l) => l.$3 == current, orElse: () => _langs.first)
        .$1;

    return GestureDetector(
      onTap: () => _showPicker(context, current),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kPurple.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPurple.withAlpha(60)),
          ),
          child: Text(currentFlag, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, String current) {
    final provider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '[TEST] 언어 선택',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ..._langs.map((lang) {
                final isSelected = lang.$3 == current;
                return ListTile(
                  leading: Text(lang.$1,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(
                    lang.$2,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? _kPurple : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: _kPurple)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    provider.setLocale(Locale(lang.$3));
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

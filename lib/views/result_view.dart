import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/analysis_result.dart';
import '../viewmodels/analysis_viewmodel.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalysisViewModel>();
    final result = vm.result;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('분석 결과'),
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
      body: result == null
          ? _StreamingView(text: vm.streamedText)
          : _ResultBody(result: result),
    );
  }
}

// ─── 스트리밍 뷰 ────────────────────────────────────────────

class _StreamingView extends StatelessWidget {
  final String text;
  const _StreamingView({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('AI가 분석 중입니다...', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text.isEmpty ? '이미지를 스캔하는 중...' : text,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
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
  const _ResultBody({required this.result});

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _statusMessage(double score) {
    if (score >= 0.8) return '상태가 매우 양호합니다!';
    if (score >= 0.5) return '조금 더 관리가 필요해요';
    return '주의가 필요한 상태입니다';
  }

  IconData _statusIcon(double score) {
    if (score >= 0.8) return Icons.thumb_up_outlined;
    if (score >= 0.5) return Icons.warning_amber_rounded;
    return Icons.error_outline;
  }

  String _buildShareText(AnalysisResult r) {
    final score = (r.stateScore * 100).round();
    final buffer = StringBuffer();
    buffer.writeln('[AiPic 분석 결과]');
    buffer.writeln('대상: ${r.targetName}');
    buffer.writeln('점수: $score / 100');
    if (r.summary.isNotEmpty) buffer.writeln('요약: ${r.summary}');
    buffer.writeln('특징: ${r.keyCharacteristics.join(', ')}');
    buffer.writeln('추천:');
    for (var i = 0; i < r.recommendations.length; i++) {
      buffer.writeln('  ${i + 1}. ${r.recommendations[i]}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnalysisViewModel>();
    final theme = Theme.of(context);
    final statusColor = _parseColor(result.statusColorCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 스코어 게이지 (그라데이션 + 카운트업) ──
          Center(
            child: _AnimatedScoreGauge(
                score: result.stateScore, color: statusColor),
          ),
          const SizedBox(height: 8),

          // ── 대상 이름 ──
          Center(
            child: Text(
              result.targetName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          // ── 상태 메시지 (아이콘 + 텍스트) ──
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(result.stateScore),
                    color: statusColor, size: 22),
                const SizedBox(width: 6),
                Text(
                  _statusMessage(result.stateScore),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

          // ── AI 한줄 요약 ──
          if (result.summary.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

          const SizedBox(height: 24),

          // ── 상세 설명 ──
          _SectionCard(
            title: '상세 설명',
            icon: Icons.description_outlined,
            child: Text(
              result.detailedDescription,
              style: theme.textTheme.bodyMedium,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // ── 주요 특징 (2열 그리드) ──
          _SectionCard(
            title: '주요 특징',
            icon: Icons.style_outlined,
            child: _CharacteristicsGrid(
              characteristics: result.keyCharacteristics,
              iconSuggestions: result.iconSuggestions,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // ── 추천 조치 (체크리스트) ──
          _SectionCard(
            title: '추천 조치',
            icon: Icons.task_alt_outlined,
            trailing: _CompletionBadge(rate: vm.completionRate),
            child: Column(
              children: result.recommendations
                  .asMap()
                  .entries
                  .map((e) => _ChecklistItem(
                        text: e.value,
                        checked: vm.checkedRecommendations.length > e.key
                            ? vm.checkedRecommendations[e.key]
                            : false,
                        onChanged: () => vm.toggleRecommendation(e.key),
                      ))
                  .toList(),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          // ── 하단 액션 버튼 ──
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: '공유하기',
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: _buildShareText(result)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('분석 결과가 클립보드에 복사되었습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.save_outlined,
                  label: '저장하기',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('준비 중입니다'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.history_outlined,
                  label: '기록 보기',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('준비 중입니다'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
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

    // 배경 트랙
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

    // 그라데이션 값 아크
    if (score > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: 0,
        endAngle: sweepFull,
        colors: const [
          Color(0xFFF44336), // 빨강
          Color(0xFFFF9800), // 주황
          Color(0xFFFFEB3B), // 노랑
          Color(0xFF4CAF50), // 초록
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

// ─── 주요 특징 2열 그리드 ───────────────────────────────────

class _CharacteristicsGrid extends StatelessWidget {
  final List<String> characteristics;
  final List<String> iconSuggestions;

  const _CharacteristicsGrid({
    required this.characteristics,
    required this.iconSuggestions,
  });

  static const _iconMap = <String, IconData>{
    'sun': Icons.wb_sunny_outlined,
    'cloud': Icons.cloud_outlined,
    'rain': Icons.water_drop_outlined,
    'umbrella': Icons.beach_access_outlined,
    'water': Icons.water_outlined,
    'tree': Icons.park_outlined,
    'park': Icons.park_outlined,
    'playground': Icons.toys_outlined,
    'safety': Icons.health_and_safety_outlined,
    'clean': Icons.cleaning_services_outlined,
    'warning': Icons.warning_amber_outlined,
    'check': Icons.check_circle_outline,
    'star': Icons.star_outline,
    'heart': Icons.favorite_outline,
    'fire': Icons.local_fire_department_outlined,
    'snow': Icons.ac_unit_outlined,
    'wind': Icons.air_outlined,
    'leaf': Icons.eco_outlined,
    'flower': Icons.local_florist_outlined,
    'bug': Icons.bug_report_outlined,
    'pet': Icons.pets_outlined,
    'food': Icons.restaurant_outlined,
    'medicine': Icons.medical_services_outlined,
    'tool': Icons.build_outlined,
    'home': Icons.home_outlined,
    'car': Icons.directions_car_outlined,
    'building': Icons.apartment_outlined,
    'people': Icons.people_outlined,
    'baby': Icons.child_care_outlined,
    'sport': Icons.sports_soccer_outlined,
    'music': Icons.music_note_outlined,
    'book': Icons.menu_book_outlined,
    'camera': Icons.camera_alt_outlined,
    'phone': Icons.phone_android_outlined,
    'clock': Icons.access_time_outlined,
    'calendar': Icons.calendar_today_outlined,
    'map': Icons.map_outlined,
    'flag': Icons.flag_outlined,
    'lock': Icons.lock_outlined,
    'key': Icons.key_outlined,
    'light': Icons.lightbulb_outline,
    'color': Icons.palette_outlined,
    'paint': Icons.brush_outlined,
    'brush': Icons.brush_outlined,
    'eye': Icons.visibility_outlined,
    'hand': Icons.pan_tool_outlined,
    'smile': Icons.sentiment_satisfied_outlined,
    'sad': Icons.sentiment_dissatisfied_outlined,
    'angry': Icons.sentiment_very_dissatisfied_outlined,
    'question': Icons.help_outline,
    'info': Icons.info_outline,
  };

  IconData _getIcon(int index) {
    if (index >= iconSuggestions.length) return Icons.label_outlined;
    final keyword = iconSuggestions[index].toLowerCase();
    // 정확히 매칭
    if (_iconMap.containsKey(keyword)) return _iconMap[keyword]!;
    // 부분 매칭
    for (final entry in _iconMap.entries) {
      if (keyword.contains(entry.key) || entry.key.contains(keyword)) {
        return entry.value;
      }
    }
    return Icons.label_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: characteristics
          .asMap()
          .entries
          .map((e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_getIcon(e.key),
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ─── 체크리스트 아이템 ──────────────────────────────────────

class _ChecklistItem extends StatelessWidget {
  final String text;
  final bool checked;
  final VoidCallback onChanged;

  const _ChecklistItem({
    required this.text,
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
                color: checked
                    ? theme.colorScheme.primary
                    : Colors.transparent,
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
                  decoration:
                      checked ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationColor: theme.colorScheme.onSurfaceVariant,
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
        '완료 $percent%',
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
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
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
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── 하단 액션 버튼 ─────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

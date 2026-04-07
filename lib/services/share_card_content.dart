// 공유용 전체 결과 카드 (비스크롤, 화면 밖 렌더링)
// result_view.dart에서 import해서 사용

import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

class ShareCard extends StatelessWidget {
  final AnalysisResult result;
  const ShareCard({super.key, required this.result});

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _statusEmoji(double score) {
    if (score >= 0.9) return '🤩';
    if (score >= 0.8) return '😊';
    if (score >= 0.6) return '😌';
    if (score >= 0.4) return '🤔';
    return '😬';
  }

  String _statusMessage(double score) {
    if (score >= 0.9) return '거의 완벽 — 손댈 데가 없음';
    if (score >= 0.8) return '상태 좋음 — 딱히 건드릴 게 없는데요';
    if (score >= 0.6) return '나쁘지 않은데, 조금 아쉽긴 함';
    if (score >= 0.4) return '슬슬 손 봐야 할 시점';
    return '지금 당장 조치가 필요합니다';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _parseColor(result.statusColorCode);
    final score = (result.stateScore * 100).round();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 앱 브랜딩
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFF6C5CE7), size: 16),
              const SizedBox(width: 6),
              const Text(
                'A.I 방구석팩폭',
                style: TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 점수 + 이모지
          Center(
            child: Column(
              children: [
                Text(_statusEmoji(result.stateScore),
                    style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 6),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    height: 1,
                  ),
                ),
                Text('/ 100',
                    style: TextStyle(
                        fontSize: 14, color: statusColor.withAlpha(180))),
                const SizedBox(height: 6),
                Text(
                  _statusMessage(result.stateScore),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 대상 이름
          Center(
            child: Text(
              result.targetName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // 요약
          if (result.summary.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6C5CE7).withAlpha(30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined,
                      color: Color(0xFF6C5CE7), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result.summary,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

          // 한줄 디스
          if (result.oneLineDis.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.oneLineDis,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 주요 특징
          if (result.keyCharacteristics.isNotEmpty) ...[
            const Text('주요 특징',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.keyCharacteristics
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: statusColor.withAlpha(40)),
                        ),
                        child: Text(
                          '🏅 $c',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 추천 조치
          if (result.recommendations.isNotEmpty) ...[
            const Text('추천 조치',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...result.recommendations
                .take(4)
                .toList()
                .asMap()
                .entries
                .map((e) {
              final boost = e.key < result.recommendationScores.length
                  ? result.recommendationScores[e.key]
                  : 3;
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_rounded,
                        size: 18, color: statusColor),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+$boost점',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 20),

          // 푸터
          const Divider(),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'A.I 방구석팩폭으로 나도 분석해보기 📸',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// 공유용 전체 결과 카드 (비스크롤, 화면 밖 렌더링)
// result_view.dart에서 import해서 사용

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/analysis_result.dart';

class ShareCard extends StatelessWidget {
  final AnalysisResult result;
  final Uint8List? imageBytes;
  const ShareCard({super.key, required this.result, this.imageBytes});

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


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _parseColor(result.statusColorCode);
    final score = (result.stateScore * 100).round();

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 분석한 사진
          if (imageBytes != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
              child: Image.memory(
                imageBytes!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFF6C5CE7), size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.appBrandName,
                style: const TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                  l10n.statusMessage(result.stateScore),
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.deepOrange.withAlpha(120),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withAlpha(50),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '🔥 AI FACT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.stateScore >= 0.8
                              ? '😏'
                              : result.stateScore >= 0.5
                                  ? '😬'
                                  : '💀',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.oneLineDis,
                            style: const TextStyle(
                              fontSize: 12,
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
            ),
          ],

          const SizedBox(height: 16),

          if (result.keyCharacteristics.isNotEmpty) ...[
            Text(l10n.keyFeatures,
                style: const TextStyle(
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

          if (result.recommendations.isNotEmpty) ...[
            Text(l10n.recommendationsLabel,
                style: const TextStyle(
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
                        l10n.scoreBoostLabel(boost),
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
          Center(
            child: Text(
              l10n.shareFooter,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

class AnalysisResult {
  final String targetName;
  final double stateScore;
  final List<String> keyCharacteristics;
  final String detailedDescription;
  final List<String> recommendations;
  final String statusColorCode;
  final String summary;
  final List<String> iconSuggestions;

  const AnalysisResult({
    required this.targetName,
    required this.stateScore,
    required this.keyCharacteristics,
    required this.detailedDescription,
    required this.recommendations,
    required this.statusColorCode,
    required this.summary,
    required this.iconSuggestions,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('analysis_result')
        ? json['analysis_result'] as Map<String, dynamic>
        : json;
    return AnalysisResult(
      targetName: data['target_name'] as String? ?? '알 수 없음',
      stateScore: (data['state_score'] as num?)?.toDouble() ?? 0.0,
      keyCharacteristics:
          (data['key_characteristics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      detailedDescription: data['detailed_description'] as String? ?? '',
      recommendations:
          (data['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      statusColorCode: data['status_color_code'] as String? ?? '#808080',
      summary: data['summary'] as String? ?? '',
      iconSuggestions:
          (data['icon_suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static AnalysisResult? tryParse(String rawText) {
    var cleaned = rawText.replaceAll(RegExp(r'```\w*\n?'), '').trim();

    final jsonStart = cleaned.indexOf('{');
    if (jsonStart < 0) return null;

    var depth = 0;
    int? jsonEnd;
    for (var i = jsonStart; i < cleaned.length; i++) {
      if (cleaned[i] == '{') depth++;
      if (cleaned[i] == '}') depth--;
      if (depth == 0) {
        jsonEnd = i;
        break;
      }
    }
    if (jsonEnd == null) return null;

    try {
      final jsonStr = cleaned.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonStr);
      return AnalysisResult.fromJson(decoded as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

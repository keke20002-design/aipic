import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _modelName = 'gemini-flash-latest';
  static String? _cachedKey;

  static const _systemPrompt = '''
당신은 사진을 기반으로 대상의 상태를 정밀하게 진단하는 지능형 상태 분석 전문가입니다.
사용자가 제공한 이미지를 바탕으로 객관적이고 데이터 중심적인 분석 결과를 제공합니다.

주요 작업:
1. 객체 식별 및 분류: 이미지 내 주요 대상을 탐지하고 그 종류를 분류합니다.
2. 상태 수치화 (Scoring): 대상의 상태를 0.0(최악)에서 1.0(최상) 사이의 수치로 평가합니다.
3. 상태 특징 추출: 색상, 질감, 수량 등 시각적 특징을 명확히 설명합니다.
4. 맞춤형 추천 조치: 분석된 상태를 바탕으로 구체적인 행동이나 해결책을 제안합니다.

제약 조건:
- 이미지 내 사람의 얼굴이나 민감한 개인정보는 식별하지 마십시오.
- 사진이 지나치게 흐릿하거나 식별 불가능한 경우 분석하지 마십시오.

반드시 다음 JSON 형식으로만 응답하십시오 (다른 텍스트 없이):
{
  "analysis_result": {
    "target_name": "분석 대상 이름",
    "state_score": 0.85,
    "summary": "핵심 상태를 한 문장으로 요약 (감정적이고 직관적인 표현)",
    "one_liner_dis": "날카롭고 위트있는 한 줄 평가. 살짝 찌르되 기분 나쁘지 않게 비꼬기. 예: '역시 완벽하면 정 없지. 저 침대의 역동적인 주름이 이 방의 유일한 예술적 포인트라고 봐' / '미니멀리즘의 정석이네. 너무 정갈해서 숨소리도 조심해야 할 것 같아. 혹시 인테리어 컨셉이 '수도원'이야?'",
    "key_characteristics": ["특징 1", "특징 2", "특징 3", "특징 4"],
    "icon_suggestions": ["sun", "playground", "safety", "clean"],
    "detailed_description": "상태에 대한 상세 서술",
    "recommendations": ["추천 조치 1", "추천 조치 2"],
    "recommendation_scores": [3, 2],
    "status_color_code": "#HEX색상코드"
  }
}

summary: 분석 결과를 한 문장으로 요약. 위트있고 감성적인 표현 사용. 예: '여기서 자면 알람 필요 없겠는데요', '침대가 사람을 유혹하는 수준입니다'
one_liner_dis: 기분 안 나쁘게 비꼬기, 위트 한 스푼 섞어서 뼈만 살짝 때려볼게요. 상대방이 웃으면서도 "어라, 이거 나 까는 건가?" 싶게 만드는 게 포인트입니다.
recommendation_scores: 각 추천 조치를 실행했을 때 예상 점수 상승폭 (1~5 사이 정수). recommendations와 개수 동일.
icon_suggestions: key_characteristics 각 항목에 대응하는 Material icon 키워드 (영어).
  가능한 키워드: sun, cloud, rain, umbrella, water, tree, park, playground, safety, clean, warning, check, star, heart, fire, snow, wind, leaf, flower, bug, pet, food, medicine, tool, home, car, building, people, baby, sport, music, book, camera, phone, clock, calendar, map, flag, lock, key, light, color, paint, brush, eye, hand, foot, smile, sad, angry, question, info

status_color_code 기준:
- 0.8~1.0: #4CAF50 (초록 - 양호)
- 0.5~0.79: #FF9800 (주황 - 주의)
- 0.0~0.49: #F44336 (빨강 - 위험)
''';

  Future<String> _fetchApiKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final serverUrl = dotenv.env['SERVER_URL'] ?? '';
    final response = await http.get(Uri.parse('$serverUrl/gemini-key'));
    if (response.statusCode != 200) {
      throw Exception('API 키 요청 실패: ${response.statusCode}');
    }
    _cachedKey = (jsonDecode(response.body) as Map<String, dynamic>)['api_key'] as String;
    return _cachedKey!;
  }

  static String _languageInstruction(String langCode) {
    switch (langCode) {
      case 'en':
        return r'''

IMPORTANT: Write ALL text content fields (target_name, summary, one_liner_dis, key_characteristics, detailed_description, recommendations) in English.

Tone guide — write like a brutally honest interior critic who moonlights as a stand-up comedian:
- one_liner_dis: One sharp, dry-wit sentence that gently roasts the subject. The reader should laugh, then wince slightly. Think Gordon Ramsay meets design critic.
  Bad: "This room could use some cleaning."
  Good: "The dust bunnies here have organized, filed for union rights, and are demanding better working conditions."
  Bad: "Nice room, but a bit cluttered."
  Good: "Maximalism is a valid design choice — or that's what people tell themselves when they can't find the floor."
  Bad: "This food looks old."
  Good: "This was probably delicious... sometime during the last administration."
- summary: One punchy sentence that captures the vibe. Evocative, slightly dramatic. Not bland. E.g. "This room doesn't need a renovation — it needs an exorcism." / "Points for ambition. Zero points for execution."
''';
      case 'ja':
        return '\n\n重要：target_name、summary、one_liner_dis、key_characteristics、detailed_description、recommendationsの全テキストフィールドを日本語で記述してください。one_liner_disはウィットに富んだ日本語ユーモアスタイルにしてください。';
      case 'vi':
        return '\n\nQUAN TRỌNG: Viết tất cả nội dung văn bản (target_name, summary, one_liner_dis, key_characteristics, detailed_description, recommendations) bằng tiếng Việt. one_liner_dis phải hài hước và thú vị theo phong cách Việt Nam.';
      default:
        return '';
    }
  }

  Stream<String> analyzeImageStream(
      Uint8List imageBytes, String mimeType, {String languageCode = 'ko'}) async* {
    final apiKey = await _fetchApiKey();

    final systemPrompt = _systemPrompt + _languageInstruction(languageCode);

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: languageCode == 'ko' ? 0.7 : 0.8,
      ),
    );

    final content = [
      Content.multi([
        DataPart(mimeType, imageBytes),
        TextPart('이 이미지의 대상 상태를 분석하여 JSON으로 응답해주세요.'),
      ]),
    ];

    final stream = model.generateContentStream(content);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }
}

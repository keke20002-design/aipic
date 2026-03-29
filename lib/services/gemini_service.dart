import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const _modelName = 'gemini-flash-latest';

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
    "key_characteristics": ["특징 1", "특징 2", "특징 3", "특징 4"],
    "icon_suggestions": ["sun", "playground", "safety", "clean"],
    "detailed_description": "상태에 대한 상세 서술",
    "recommendations": ["추천 조치 1", "추천 조치 2"],
    "status_color_code": "#HEX색상코드"
  }
}

summary: 분석 결과를 한 문장으로 요약. 직관적이고 감정이 담긴 표현 사용.
icon_suggestions: key_characteristics 각 항목에 대응하는 Material icon 키워드 (영어).
  가능한 키워드: sun, cloud, rain, umbrella, water, tree, park, playground, safety, clean, warning, check, star, heart, fire, snow, wind, leaf, flower, bug, pet, food, medicine, tool, home, car, building, people, baby, sport, music, book, camera, phone, clock, calendar, map, flag, lock, key, light, color, paint, brush, eye, hand, foot, smile, sad, angry, question, info

status_color_code 기준:
- 0.8~1.0: #4CAF50 (초록 - 양호)
- 0.5~0.79: #FF9800 (주황 - 주의)
- 0.0~0.49: #F44336 (빨강 - 위험)
''';

  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  Stream<String> analyzeImageStream(
      Uint8List imageBytes, String mimeType) async* {
    final content = [
      Content.multi([
        DataPart(mimeType, imageBytes),
        TextPart('이 이미지의 대상 상태를 분석하여 JSON으로 응답해주세요.'),
      ]),
    ];

    final stream = _model.generateContentStream(content);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }
}

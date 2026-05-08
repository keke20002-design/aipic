import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
    Locale('vi'),
  ];

  String get _lang => locale.languageCode;

  String _s(String ko, String en, String ja, String vi) {
    switch (_lang) {
      case 'en':
        return en;
      case 'ja':
        return ja;
      case 'vi':
        return vi;
      default:
        return ko;
    }
  }

  // ── App ──────────────────────────────────────────────────────
  String get appBrandName =>
      _s('A.I 방구석팩폭', 'A.I Room Roast', 'A.I 部屋ダメ出し', 'A.I Chuyên Gia Phòng');

  // ── Home ─────────────────────────────────────────────────────
  String get historyView => _s('기록 보기', 'History', '履歴', 'Lịch sử');
  String get cameraCapture =>
      _s('카메라로 촬영', 'Camera', 'カメラで撮影', 'Chụp bằng camera');
  String get gallerySelect =>
      _s('갤러리에서 선택', 'From Gallery', 'ギャラリーから選択', 'Chọn từ thư viện');
  String get tagline =>
      _s('거짓말 못하는 렌즈', 'The Lens That Never Lies', '嘘をつかないレンズ', 'Ống kính trung thực');
  String get takeNow => _s('지금 바로 찍기', 'Take Photo', '今すぐ撮影', 'Chụp ngay');
  String get pickFromGallery =>
      _s('인생샷 고르기', 'Pick a Shot', 'ベストショット', 'Chọn ảnh đẹp');
  String get warningTitle => _s(
    '팩폭주의 : 사진은 거짓말 안합니다',
    "Photos don't lie.",
    '注意：写真は嘘をつかない',
    'Cảnh báo: Ảnh không nói dối',
  );
  String get scanStart =>
      _s('지금 바로 스캔 시작', 'Tap to Start Scan', 'タップしてスキャン開始', 'Nhấn để bắt đầu');
  String get teaser => _s(
    '이거 분석 안 하면 모른다',
    "You won't know until you scan",
    '分析しないとわからない',
    'Bạn sẽ không biết nếu không phân tích',
  );
  String get analysisExample =>
      _s('분석 예시', 'Sample Analysis', '分析例', 'Ví dụ phân tích');
  String get cleanlinessLabel =>
      _s('청결도', 'Cleanliness', '清潔度', 'Sạch sẽ');
  String get organizationLabel =>
      _s('정리력', 'Organization', '整理力', 'Gọn gàng');
  String get analyzeStartEnabled => _s(
    '🚀  분석 시작하기',
    '🚀  Start Analysis',
    '🚀  分析開始',
    '🚀  Bắt đầu phân tích',
  );
  String get analyzeStartDisabled => _s(
    '사진을 선택하면 시작됩니다',
    'Select a photo to start',
    '写真を選択してください',
    'Chọn ảnh để bắt đầu',
  );
  String get scoreUnit => _s('점', 'pts', '点', 'đ');

  List<String> get previewQuotes {
    switch (_lang) {
      case 'en':
        return [
          '"Impressive disorder — this room has a unique artistic vision called chaos"',
          '"Five-star experience, minus the complimentary turndown service"',
          '"The negative space is so vast, it\'s basically a meditation retreat"',
          '"Minimalism at its finest. Is the interior concept a monastery?"',
        ];
      case 'ja':
        return [
          '"この混乱した創造性は独自の芸術的ビジョン、つまりカオスですね"',
          '"5つ星体験ですね。ターンダウンサービスがないことを除けば"',
          '"ネガティブスペースが広大すぎて、まるで瞑想リトリートのようです"',
          '"ミニマリズムの極致ですね。インテリアのコンセプトは\'修道院\'ですか？"',
        ];
      case 'vi':
        return [
          '"Sự sáng tạo trong hỗn loạn thật ấn tượng — căn phòng này có phong cách hỗn độn riêng"',
          '"Trải nghiệm 5 sao, trừ dịch vụ dọn giường buổi tối"',
          '"Không gian trống quá rộng, như một khóa tu thiền định"',
          '"Tối giản đỉnh cao. Concept nội thất của bạn là \'tu viện\' à?"',
        ];
      default:
        return [
          '"역시 완벽하면 정 없지. 저 침대의 역동적인 주름이 이 방의 유일한 예술적 포인트라고 봐"',
          '"이 정도면 5성급이지. 체크아웃 시간 없는 거 빼고는 호텔이랑 다를 게 뭐야?"',
          '"여백의 미가 아주 태평양 수준인데? 덕분에 내 마음이 아주 평온해지다 못해 잠이 쏟아지려고 해"',
          '"미니멀리즘의 정석이네. 혹시 인테리어 컨셉이 \'수도원\'이야?"',
        ];
    }
  }

  // ── Result ───────────────────────────────────────────────────
  String get analysisResult =>
      _s('분석 결과', 'Analysis Result', '分析結果', 'Kết quả phân tích');
  String get analyzing =>
      _s('분석 진행 중', 'Analyzing...', '分析中', 'Đang phân tích...');
  String get analysisFailed => _s(
    '분석에 실패했습니다',
    'Analysis Failed',
    '分析に失敗しました',
    'Phân tích thất bại',
  );
  String get unknownError => _s(
    '알 수 없는 오류가 발생했습니다.',
    'An unknown error occurred.',
    '不明なエラーが発生しました。',
    'Đã xảy ra lỗi không xác định.',
  );
  String get retryAnalysis =>
      _s('다시 분석하기', 'Retry Analysis', 'もう一度分析', 'Thử phân tích lại');
  String get reselectPhoto =>
      _s('사진 다시 선택', 'Select Again', '写真を再選択', 'Chọn lại ảnh');
  String get detailedDescription =>
      _s('상세 설명', 'Details', '詳細説明', 'Mô tả chi tiết');
  String get keyFeatures =>
      _s('주요 특징', 'Key Features', '主な特徴', 'Đặc điểm chính');
  String get recommendationsLabel =>
      _s('추천 조치', 'Recommendations', '推奨対策', 'Khuyến nghị');
  String get unlockHiddenResult => _s(
    '🔓 히든 결과 해제',
    '🔓 Unlock Hidden Results',
    '🔓 隠し結果を解除',
    '🔓 Mở kết quả ẩn',
  );
  String get notSatisfied => _s(
    '이 정도로 만족할 건 아니죠?',
    'Not satisfied yet?',
    'まだ満足しませんよね？',
    'Chưa hài lòng chứ?',
  );
  String get watchToUnlock =>
      _s('간단히 보고 잠금 해제', 'Watch ad to unlock', '広告を見て解除', 'Xem quảng cáo để mở khóa');
  String get shareQuestion =>
      _s('이 정도면 자랑 가능?', 'Worth Sharing?', 'これは自慢できる？', 'Đáng chia sẻ không?');
  String get saveResult =>
      _s('결과저장하기', 'Save Result', '結果を保存', 'Lưu kết quả');
  String get shareError => _s(
    '공유 준비 중 오류가 발생했습니다',
    'Error preparing share',
    '共有の準備中にエラーが発生しました',
    'Lỗi khi chuẩn bị chia sẻ',
  );
  String get saveError => _s(
    '저장 준비 중 오류가 발생했습니다',
    'Error preparing save',
    '保存の準備中にエラーが発生しました',
    'Lỗi khi chuẩn bị lưu',
  );
  String get savedToGallery => _s(
    '갤러리에 저장됐습니다 📸',
    'Saved to Gallery 📸',
    'ギャラリーに保存されました 📸',
    'Đã lưu vào thư viện 📸',
  );
  String get saveToGalleryFailed => _s(
    '갤러리 저장에 실패했습니다',
    'Failed to save to Gallery',
    'ギャラリーへの保存に失敗しました',
    'Lưu vào thư viện thất bại',
  );
  String get seeMore => _s('자세히 보기', 'See More', '詳しく見る', 'Xem thêm');
  String get statusPerfect => _s(
    '거의 완벽 — 손댈 데가 없음',
    'Nearly Perfect — Nothing to Fix',
    'ほぼ完璧 — 改善不要',
    'Gần như hoàn hảo',
  );
  String get statusGood => _s(
    '상태 좋음 — 딱히 건드릴 게 없는데요',
    'Good — Not Much to Change',
    '状態良好 — 特に変えることなし',
    'Tốt — Không cần thay đổi nhiều',
  );
  String get statusOkay => _s(
    '나쁘지 않은데, 조금 아쉽긴 함',
    'Not Bad, Could Be Better',
    '悪くないが、少し惜しい',
    'Không tệ, nhưng còn thiếu chút',
  );
  String get statusFair => _s(
    '슬슬 손 봐야 할 시점',
    'Time to Make Some Changes',
    'そろそろ手を入れる時期',
    'Đã đến lúc cải thiện',
  );
  String get statusBad => _s(
    '지금 당장 조치가 필요합니다',
    'Immediate Action Needed',
    '今すぐ対処が必要です',
    'Cần hành động ngay',
  );

  String completionPercent(int n) =>
      _s('완료 $n%', 'Done $n%', '完了 $n%', 'Xong $n%');
  String scoreBoostLabel(int n) =>
      _s('+$n 점', '+$n pts', '+$n 点', '+$n đ');

  String statusMessage(double score) {
    if (score >= 0.9) return statusPerfect;
    if (score >= 0.8) return statusGood;
    if (score >= 0.6) return statusOkay;
    if (score >= 0.4) return statusFair;
    return statusBad;
  }

  List<String> get streamingSteps {
    switch (_lang) {
      case 'en':
        return [
          '🧠 Analyzing room structure...',
          '📦 Calculating clutter density...',
          '🧹 Scanning cleanliness...',
          '😶 Generating roast line...',
        ];
      case 'ja':
        return [
          '🧠 部屋の構造を分析中...',
          '📦 物の密度を計算中...',
          '🧹 清潔状態をスキャン中...',
          '😶 コメント生成中...',
        ];
      case 'vi':
        return [
          '🧠 Đang phân tích cấu trúc phòng...',
          '📦 Đang tính mật độ đồ vật...',
          '🧹 Đang quét mức độ sạch sẽ...',
          '😶 Đang tạo câu nhận xét...',
        ];
      default:
        return [
          '🧠 AI가 방 구조 분석 중...',
          '📦 물건 밀집도 계산 중...',
          '🧹 청결 상태 스캔 중...',
          '😶 팩폭 문장 생성 중...',
        ];
    }
  }

  List<String> get streamingDrips {
    switch (_lang) {
      case 'en':
        return [
          '"Hmm… this could use some tidying"',
          '"Wait… this is worse than I thought"',
          '"AI is thinking… should I even say this?"',
        ];
      case 'ja':
        return [
          '"うーん…整理が必要だな"',
          '"ちょっと待って…予想より深刻だ"',
          '"AIが悩んでいます…言っていいものか"',
        ];
      case 'vi':
        return [
          '"Hmm… cần dọn dẹp một chút"',
          '"Đợi đã… tệ hơn tôi nghĩ"',
          '"AI đang suy nghĩ… có nên nói không"',
        ];
      default:
        return [
          '"흠… 이건 좀 정리가 필요해 보이는데"',
          '"잠깐만… 이건 예상보다 심각한데?"',
          '"AI가 고민 중입니다… 말해도 될지"',
        ];
    }
  }

  // ── History ──────────────────────────────────────────────────
  String get analysisHistory =>
      _s('분석 기록', 'Analysis History', '分析履歴', 'Lịch sử phân tích');
  String get deleteAll => _s('전체 삭제', 'Delete All', '全て削除', 'Xóa tất cả');
  String get deleteAllTitle => _s(
    '기록 전체 삭제',
    'Delete All Records',
    '全記録を削除',
    'Xóa tất cả lịch sử',
  );
  String get deleteAllContent => _s(
    '모든 분석 기록을 삭제할까요?',
    'Delete all analysis records?',
    '全ての分析記録を削除しますか？',
    'Xóa tất cả lịch sử phân tích?',
  );
  String get cancel => _s('취소', 'Cancel', 'キャンセル', 'Hủy');
  String get delete => _s('삭제', 'Delete', '削除', 'Xóa');
  String get noHistory => _s(
    '아직 분석 기록이 없어요',
    'No analysis history yet',
    'まだ分析記録がありません',
    'Chưa có lịch sử phân tích',
  );
  String get noHistoryDesc => _s(
    '사진을 분석하면 여기에 자동으로 저장됩니다',
    'Analyzed photos will be saved here',
    '写真を分析すると自動的に保存されます',
    'Ảnh đã phân tích sẽ được lưu tại đây',
  );
  String get justNow => _s('방금 전', 'Just now', 'たった今', 'Vừa xong');
  String minutesAgo(int n) =>
      _s('$n분 전', '${n}m ago', '$n分前', '$n phút trước');
  String hoursAgo(int n) =>
      _s('$n시간 전', '${n}h ago', '$n時間前', '$n giờ trước');
  String daysAgo(int n) =>
      _s('$n일 전', '${n}d ago', '$n日前', '$n ngày trước');

  // ── Share Card ───────────────────────────────────────────────
  String get shareFooter => _s(
    'A.I 방구석팩폭으로 나도 분석해보기 📸',
    'Try A.I Room Roast yourself 📸',
    'A.I 部屋ダメ出しで自分も分析 📸',
    'Thử phân tích của bạn 📸',
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ko', 'en', 'ja', 'vi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

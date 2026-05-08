import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/analysis_result.dart';
import '../services/gemini_service.dart';
import '../services/history_service.dart';

enum AnalysisState { idle, loading, streaming, done, error }

class AnalysisViewModel extends ChangeNotifier {
  final GeminiService _service = GeminiService();

  AnalysisState _state = AnalysisState.idle;
  String _streamedText = '';
  AnalysisResult? _result;
  AnalysisResult? _pendingResult;
  bool _awaitingAdBeforeResult = false;
  String _errorMessage = '';
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  List<bool> _checkedRecommendations = [];
  String _languageCode = 'ko';

  AnalysisState get state => _state;
  String get streamedText => _streamedText;
  AnalysisResult? get result => _result;
  bool get awaitingAdBeforeResult => _awaitingAdBeforeResult;
  String get errorMessage => _errorMessage;
  XFile? get selectedImage => _selectedImage;
  Uint8List? get imageBytes => _imageBytes;
  List<bool> get checkedRecommendations => _checkedRecommendations;

  bool get isLoading =>
      _state == AnalysisState.loading || _state == AnalysisState.streaming;

  double get completionRate {
    if (_checkedRecommendations.isEmpty) return 0.0;
    final checked = _checkedRecommendations.where((v) => v).length;
    return checked / _checkedRecommendations.length;
  }

  Future<void> setImage(XFile image) async {
    _selectedImage = image;
    _imageBytes = await image.readAsBytes();
    _state = AnalysisState.idle;
    _result = null;
    _streamedText = '';
    _errorMessage = '';
    _checkedRecommendations = [];
    notifyListeners();
  }

  Future<void> analyzeImage({String? languageCode}) async {
    if (languageCode != null) _languageCode = languageCode;
    if (_selectedImage == null || _imageBytes == null) return;

    _state = AnalysisState.loading;
    _streamedText = '';
    _result = null;
    _errorMessage = '';
    _checkedRecommendations = [];
    notifyListeners();

    const maxRetries = 3;
    final mimeType = _getMimeType(_selectedImage!.name);

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _state = AnalysisState.streaming;
        _streamedText = '';
        notifyListeners();

        await (() async {
          await for (final chunk in _service.analyzeImageStream(
              _imageBytes!, mimeType, languageCode: _languageCode)) {
            _streamedText += chunk;
            notifyListeners();
          }
        })().timeout(const Duration(seconds: 60));

        final parsed = AnalysisResult.tryParse(_streamedText);
        if (parsed != null) {
          _pendingResult = parsed;
          _checkedRecommendations =
              List.filled(parsed.recommendations.length, false);
          _state = AnalysisState.done;
          _awaitingAdBeforeResult = true;
          await HistoryService.save(parsed);
          notifyListeners();
          return;
        } else {
          debugPrint('파싱 실패 원본 (시도 $attempt): $_streamedText');
          if (attempt == maxRetries) {
            _errorMessage = '분석 결과를 파싱할 수 없습니다. 다시 시도해주세요.';
            _state = AnalysisState.error;
          }
        }
      } on TimeoutException {
        debugPrint('타임아웃 (시도 $attempt)');
        if (attempt == maxRetries) {
          _errorMessage = '분석 시간이 너무 오래 걸립니다.\n잠시 후 다시 시도해주세요.';
          _state = AnalysisState.error;
        }
      } catch (e) {
        debugPrint('오류 (시도 $attempt): $e');
        if (attempt == maxRetries) {
          final msg = e.toString();
          if (msg.contains('high demand') || msg.contains('scaling')) {
            _errorMessage = '잠시 후에 다시 시도해보세요. A.I 서버가 안정화되면 다시 서비스를 이용할 수 있습니다';
          } else {
            _errorMessage = msg;
          }
          _state = AnalysisState.error;
        }
      }

      if (_state != AnalysisState.done && attempt < maxRetries) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    notifyListeners();
  }

  void revealResult() {
    if (_pendingResult == null) return;
    _result = _pendingResult;
    _pendingResult = null;
    _awaitingAdBeforeResult = false;
    notifyListeners();
  }

  void toggleRecommendation(int index) {
    if (index < 0 || index >= _checkedRecommendations.length) return;
    _checkedRecommendations[index] = !_checkedRecommendations[index];
    notifyListeners();
  }

  String _getMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  void reset() {
    _state = AnalysisState.idle;
    _streamedText = '';
    _result = null;
    _pendingResult = null;
    _awaitingAdBeforeResult = false;
    _errorMessage = '';
    _selectedImage = null;
    _imageBytes = null;
    _checkedRecommendations = [];
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/analysis_result.dart';
import '../services/gemini_service.dart';

enum AnalysisState { idle, loading, streaming, done, error }

class AnalysisViewModel extends ChangeNotifier {
  final GeminiService _service = GeminiService();

  AnalysisState _state = AnalysisState.idle;
  String _streamedText = '';
  AnalysisResult? _result;
  String _errorMessage = '';
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  List<bool> _checkedRecommendations = [];

  AnalysisState get state => _state;
  String get streamedText => _streamedText;
  AnalysisResult? get result => _result;
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

  Future<void> analyzeImage() async {
    if (_selectedImage == null || _imageBytes == null) return;

    _state = AnalysisState.loading;
    _streamedText = '';
    _result = null;
    _errorMessage = '';
    _checkedRecommendations = [];
    notifyListeners();

    try {
      _state = AnalysisState.streaming;
      notifyListeners();

      final mimeType = _getMimeType(_selectedImage!.name);
      await for (final chunk
          in _service.analyzeImageStream(_imageBytes!, mimeType)) {
        _streamedText += chunk;
        notifyListeners();
      }

      final parsed = AnalysisResult.tryParse(_streamedText);
      if (parsed != null) {
        _result = parsed;
        _checkedRecommendations =
            List.filled(parsed.recommendations.length, false);
        _state = AnalysisState.done;
      } else {
        debugPrint('파싱 실패 원본: $_streamedText');
        _errorMessage = '분석 결과를 파싱할 수 없습니다. 다시 시도해주세요.';
        _state = AnalysisState.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = AnalysisState.error;
    }
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
    _errorMessage = '';
    _selectedImage = null;
    _imageBytes = null;
    _checkedRecommendations = [];
    notifyListeners();
  }
}

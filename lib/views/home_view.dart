import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/analysis_viewmodel.dart';
import 'result_view.dart';

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
    final theme = Theme.of(context);
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
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: theme.colorScheme.primary),
                title: const Text('카메라로 촬영'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(context, ImageSource.camera, vm);
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: theme.colorScheme.primary),
                title: const Text('갤러리에서 선택'),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'AiPic',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: vm.selectedImage == null
          ? FloatingActionButton(
              onPressed: () => _showPickerSheet(context, vm),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_a_photo_rounded, size: 26),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이미지 프리뷰 영역
              Expanded(
                child: _ImagePreview(imageBytes: vm.imageBytes),
              ),
              const SizedBox(height: 24),

              // 이미지 선택 버튼
              Row(
                children: [
                  Expanded(
                    child: _OutlineButton(
                      icon: Icons.camera_alt_outlined,
                      label: '카메라',
                      onTap: vm.isLoading
                          ? null
                          : () => _pickImage(context, ImageSource.camera, vm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OutlineButton(
                      icon: Icons.photo_library_outlined,
                      label: '갤러리',
                      onTap: vm.isLoading
                          ? null
                          : () => _pickImage(context, ImageSource.gallery, vm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 분석 버튼
              _AnalyzeButton(
                enabled: vm.selectedImage != null && !vm.isLoading,
                isLoading: vm.isLoading,
                onTap: () async {
                  await vm.analyzeImage();
                  if (context.mounted && vm.state == AnalysisState.done) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: vm,
                          child: const ResultView(),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),

              // 에러 메시지
              if (vm.state == AnalysisState.error)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vm.errorMessage,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? imageBytes;
  const _ImagePreview({this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (imageBytes != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '사진을 선택하세요',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _AnalyzeButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onTap : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Text(
              '분석 시작',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}

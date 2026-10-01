import '../../domain/entities/template_asset.dart';

enum TemplatePickerStatus { initial, loading, loaded, saving, failure }

class TemplatePickerState {
  const TemplatePickerState({
    this.status = TemplatePickerStatus.initial,
    this.templates = const [],
    this.selectedId,
    this.errorMessage,
  });
  final TemplatePickerStatus status;
  final List<TemplateAsset> templates;
  final String? selectedId;
  final String? errorMessage;
}

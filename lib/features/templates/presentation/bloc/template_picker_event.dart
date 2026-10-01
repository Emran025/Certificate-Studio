import '../../domain/entities/template_asset.dart';

sealed class TemplatePickerEvent {
  const TemplatePickerEvent();
}

final class TemplatesRequested extends TemplatePickerEvent {
  const TemplatesRequested();
}

final class TemplateAdded extends TemplatePickerEvent {
  const TemplateAdded(this.template);
  final TemplateAsset template;
}

final class TemplateSelected extends TemplatePickerEvent {
  const TemplateSelected(this.id);
  final String id;
}

final class TemplateUpdated extends TemplatePickerEvent {
  const TemplateUpdated(this.template);
  final TemplateAsset template;
}

final class TemplateDeleted extends TemplatePickerEvent {
  const TemplateDeleted(this.id);
  final String id;
}

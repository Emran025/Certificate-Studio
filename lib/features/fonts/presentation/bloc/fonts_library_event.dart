import '../../domain/entities/font_asset.dart';

sealed class FontsLibraryEvent {
  const FontsLibraryEvent();
}

final class FontsRequested extends FontsLibraryEvent {
  const FontsRequested();
}

final class FontAdded extends FontsLibraryEvent {
  const FontAdded(this.font, this.bytes);
  final FontAsset font;
  final List<int> bytes;
}

final class FontSelected extends FontsLibraryEvent {
  const FontSelected(this.id);
  final String id;
}

final class FontDeleted extends FontsLibraryEvent {
  const FontDeleted(this.id);
  final String id;
}

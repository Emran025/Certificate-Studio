import '../../domain/entities/font_asset.dart';

enum FontsLibraryStatus { initial, loading, loaded, saving, failure }

class FontsLibraryState {
  const FontsLibraryState({
    this.status = FontsLibraryStatus.initial,
    this.fonts = const [],
    this.selectedId,
    this.errorMessage,
  });
  final FontsLibraryStatus status;
  final List<FontAsset> fonts;
  final String? selectedId;
  final String? errorMessage;
}

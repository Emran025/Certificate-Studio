part of '../fonts_library_screen.dart';

class FontsLibraryScreen extends StatefulWidget {
  const FontsLibraryScreen({super.key, required this.database, this.projectId});
  final AppDatabase database;
  final String? projectId;
  @override
  State<FontsLibraryScreen> createState() => _FontsLibraryScreenState();
}

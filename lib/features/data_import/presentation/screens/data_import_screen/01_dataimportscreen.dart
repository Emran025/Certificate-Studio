part of '../data_import_screen.dart';

class DataImportScreen extends StatefulWidget {
  const DataImportScreen({
    super.key,
    required this.database,
    required this.projectId,
  });

  final AppDatabase database;
  final String projectId;

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

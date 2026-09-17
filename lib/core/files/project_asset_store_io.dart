import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> saveProjectBackground({
  required String fileName,
  required List<int> bytes,
}) async {
  final directory = await getApplicationSupportDirectory();
  final backgrounds = Directory('${directory.path}${Platform.pathSeparator}project_backgrounds');
  await backgrounds.create(recursive: true);
  final file = File('${backgrounds.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

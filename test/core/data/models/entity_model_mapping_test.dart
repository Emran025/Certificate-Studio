import 'package:flutter_test/flutter_test.dart';

import 'package:certificate_studio/core/data/models/file_reference_model.dart';
import 'package:certificate_studio/core/entities/file_reference.dart';
import 'package:certificate_studio/features/certificates/data/models/certificate_record_model.dart';
import 'package:certificate_studio/features/certificates/domain/entities/certificate_record.dart';
import 'package:certificate_studio/features/fonts/data/models/font_asset_model.dart';
import 'package:certificate_studio/features/settings/data/models/app_settings_model.dart';
import 'package:certificate_studio/features/settings/domain/entities/app_settings.dart';
import 'package:certificate_studio/features/templates/data/models/template_asset_model.dart';

void main() {
  group('data models', () {
    test('certificate model maps database rows into a pure entity', () {
      final entity = CertificateRecordModel.fromRows(
        {
          'id': 'certificate-1',
          'status': 'generated',
          'project_id': 'project-1',
          'record_id': 'record-1',
          'file_path': 'artifact://certificates/certificate-1.pdf',
          'image_path': 'artifact://certificates/certificate-1.png',
        },
        {
          'class_name': 'A001',
          'data_json': '{"name":"Ahmed","course":"Flutter"}',
        },
      );

      expect(entity, isA<CertificateRecord>());
      expect(entity.id, 'certificate-1');
      expect(entity.className, 'A001');
      expect(entity.recipient, 'Ahmed');
      expect(entity.valueFor('course'), 'Flutter');
    });

    test(
      'settings model owns JSON serialization and legacy default migration',
      () {
        final settings = AppSettingsModel.fromJson({
          'theme_mode': 'dark',
          'accent_color': 0xFF176B87,
          'language': 'en',
        });

        expect(settings, isA<AppSettings>());
        expect(settings.themeMode, AppThemeMode.dark);
        expect(settings.languageCode, 'en');
        expect(settings.toJson()['theme_mode'], 'dark');
      },
    );

    test('asset models map to database-compatible rows', () {
      final font = FontAssetModel(
        id: 'font-1',
        name: 'Cairo',
        family: 'Cairo',
        filePath: '/fonts/cairo.ttf',
        format: 'ttf',
      );
      final template = TemplateAssetModel(
        id: 'template-1',
        name: 'Default',
        filePath: '/templates/default.png',
        width: 1600,
        height: 1100,
        dpi: 300,
        format: 'png',
      );

      expect(font.toRow(bytes: [1, 2], now: 'now')['font_bytes'], [1, 2]);
      expect(template.toRow(now: 'now')['width'], 1600);
    });

    test('file reference JSON belongs to its data model', () {
      const entity = FileReference(
        path: '/tmp/file.pdf',
        fileName: 'file.pdf',
        extension: 'pdf',
      );
      final model = FileReferenceModel.fromJson({
        'path': entity.path,
        'fileName': entity.fileName,
        'extension': entity.extension,
      });

      expect(model.toJson(), {
        'path': '/tmp/file.pdf',
        'fileName': 'file.pdf',
        'extension': 'pdf',
      });
    });
  });
}

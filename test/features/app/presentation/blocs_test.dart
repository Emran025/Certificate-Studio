import 'dart:typed_data';

import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/app/domain/entities/workspace_metrics.dart';
import 'package:certificate_studio/features/app/presentation/bloc/startup_bloc.dart';
import 'package:certificate_studio/features/app/presentation/controllers/workspace_metrics_bloc.dart';
import 'package:certificate_studio/features/app/domain/repositories/workspace_repository.dart';
import 'package:certificate_studio/features/app/domain/usecases/get_workspace_metrics.dart';
import 'package:certificate_studio/features/certificates/domain/entities/certificate_record.dart';
import 'package:certificate_studio/features/certificates/domain/repositories/certificate_repository.dart';
import 'package:certificate_studio/features/certificates/domain/usecases/get_certificates.dart';
import 'package:certificate_studio/features/certificates/presentation/bloc/certificate_library_bloc.dart';
import 'package:certificate_studio/features/data_import/domain/entities/imported_table.dart';
import 'package:certificate_studio/features/data_import/domain/repositories/data_import_repository.dart';
import 'package:certificate_studio/features/data_import/domain/usecases/import_excel.dart';
import 'package:certificate_studio/features/data_import/domain/usecases/paste_table.dart';
import 'package:certificate_studio/features/data_import/presentation/bloc/data_import_bloc.dart';
import 'package:certificate_studio/features/fonts/domain/entities/font_asset.dart';
import 'package:certificate_studio/features/fonts/domain/repositories/font_repository.dart';
import 'package:certificate_studio/features/fonts/presentation/bloc/fonts_library_bloc.dart';
import 'package:certificate_studio/features/institution/domain/entities/institution.dart';
import 'package:certificate_studio/features/institution/domain/repositories/institution_repository.dart';
import 'package:certificate_studio/features/projects/domain/entities/project.dart';
import 'package:certificate_studio/features/projects/domain/repositories/project_repository.dart';
import 'package:certificate_studio/features/projects/domain/usecases/delete_project.dart';
import 'package:certificate_studio/features/projects/presentation/bloc/projects_library_bloc.dart';
import 'package:certificate_studio/features/templates/domain/entities/template_asset.dart';
import 'package:certificate_studio/features/templates/domain/repositories/template_repository.dart';
import 'package:certificate_studio/features/templates/presentation/bloc/template_picker_bloc.dart';
import 'package:certificate_studio/features/verification/domain/certificate_verification_service.dart';
import 'package:certificate_studio/features/verification/presentation/bloc/verification_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final institution = Institution(
    id: 'institution-1',
    institutionId: 'academy-1',
    name: 'Academy',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final project = Project(
    id: 'project-1',
    institutionId: 'academy-1',
    name: 'Course',
    projectKeyReference: 'key-1',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final template = const TemplateAsset(
    id: 'template-1',
    name: 'Template',
    filePath: '/tmp/template.png',
    width: 1920,
    height: 1080,
    dpi: 300,
    format: 'png',
  );
  final font = const FontAsset(
    id: 'font-1',
    name: 'Cairo',
    family: 'Cairo',
    filePath: '/tmp/cairo.ttf',
    format: 'ttf',
  );
  final certificate = const CertificateRecord(
    id: 'certificate-1',
    status: 'generated',
    projectId: 'project-1',
    recordId: 'record-1',
    className: 'A001',
    data: {'name': 'Sara'},
  );

  test('StartupBloc covers loading, loaded and failure states', () async {
    final repository = FakeInstitutionRepository(current: institution);
    final bloc = StartupBloc(repository);
    addTearDown(bloc.close);
    final loaded = expectLater(
      bloc.stream,
      emitsThrough(
        predicate<StartupState>(
          (state) => state.status == StartupStatus.loaded,
        ),
      ),
    );
    bloc.add(const StartupRequested());
    await loaded;
    expect(bloc.state.institution?.name, 'Academy');

    repository.shouldFail = true;
    final failed = expectLater(
      bloc.stream,
      emitsThrough(
        predicate<StartupState>(
          (state) => state.status == StartupStatus.failure,
        ),
      ),
    );
    bloc.add(const StartupRequested());
    await failed;
    expect(bloc.state.errorMessage, isNotNull);
  });

  test('WorkspaceMetricsBloc covers loaded and failure states', () async {
    var fail = false;
    final bloc = WorkspaceMetricsBloc(
      GetWorkspaceMetricsForTest(() async {
        if (fail) throw StateError('metrics failed');
        return const WorkspaceMetrics(templates: 2, fonts: 3, certificates: 4);
      }),
    );
    addTearDown(bloc.close);
    final loaded = expectLater(
      bloc.stream,
      emitsThrough(
        predicate<WorkspaceMetricsState>(
          (state) => state.status == WorkspaceMetricsStatus.loaded,
        ),
      ),
    );
    bloc.add(const WorkspaceMetricsRequested());
    await loaded;
    expect(bloc.state.metrics.certificates, 4);
    fail = true;
    final failed = expectLater(
      bloc.stream,
      emitsThrough(
        predicate<WorkspaceMetricsState>(
          (state) => state.status == WorkspaceMetricsStatus.failure,
        ),
      ),
    );
    bloc.add(const WorkspaceMetricsRequested());
    await failed;
    expect(bloc.state.errorMessage, contains('metrics failed'));
  });

  test(
    'DataImportBloc covers load, paste, table update, excel and errors',
    () async {
      var saved = const ImportedTable(
        columns: ['name'],
        rows: [
          {'name': 'Initial'},
        ],
      );
      final bloc = DataImportBloc(
        projectId: 'project-1',
        pasteTable: PasteTable(FakeImportRepository(() => saved)),
        importExcel: ImportExcel(FakeImportRepository(() => saved)),
        loadTable: () async => saved,
        saveTable: (table) async => saved = table,
      );
      addTearDown(bloc.close);
      bloc.add(const DataImportRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, DataImportStatus.loaded);
      bloc.add(const PasteTableRequested('name\nSara'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, DataImportStatus.loaded);
      bloc.add(
        TableUpdatedRequested(
          const ImportedTable(columns: ['email'], rows: []),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(saved.columns, ['email']);
      bloc.add(ExcelImportRequested(Uint8List.fromList([1, 2])));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, DataImportStatus.failure);
      bloc.add(const DataImportErrorReported('manual error'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.errorMessage, 'manual error');
    },
  );

  test('ProjectsLibraryBloc loads and deletes a project', () async {
    final repository = FakeProjectRepository([project]);
    final bloc = ProjectsLibraryBloc(
      repository,
      DeleteProject(repository, InMemoryKeyStorage()),
      'academy-1',
    );
    addTearDown(bloc.close);
    bloc.add(const ProjectsRequested());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.projects, [project]);
    bloc.add(ProjectDeleted(project));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.projects, isEmpty);
    expect(bloc.state.deletedProjectName, 'Course');
  });

  test(
    'TemplatePickerBloc covers add, select, update, delete and protected delete',
    () async {
      final repository = FakeTemplateRepository([template]);
      final bloc = TemplatePickerBloc(repository, 'project-1');
      addTearDown(bloc.close);
      bloc.add(const TemplatesRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.templates, [template]);
      bloc.add(const TemplateSelected('template-1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.selectedId, 'template-1');
      bloc.add(TemplateUpdated(template));
      await Future<void>.delayed(Duration.zero);
      bloc.add(TemplateAdded(template));
      await Future<void>.delayed(Duration.zero);
      repository.used = true;
      bloc.add(const TemplateDeleted('template-1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, TemplatePickerStatus.failure);
      expect(bloc.state.errorMessage, contains('cannot be deleted'));
    },
  );

  test(
    'FontsLibraryBloc covers add, load, select, delete and failure',
    () async {
      final repository = FakeFontRepository([font]);
      final bloc = FontsLibraryBloc(repository, 'project-1');
      addTearDown(bloc.close);
      bloc.add(const FontsRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.fonts.single.id, 'font-1');
      bloc.add(const FontSelected('font-1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.selectedId, 'font-1');
      bloc.add(FontAdded(font, const [1, 2, 3]));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FontDeleted('font-1'));
      await Future<void>.delayed(Duration.zero);
      repository.shouldFail = true;
      bloc.add(const FontsRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, FontsLibraryStatus.failure);
    },
  );

  test(
    'CertificateLibraryBloc loads certificates and exposes repository errors',
    () async {
      final repository = FakeCertificateRepository([certificate]);
      final bloc = CertificateLibraryBloc(
        GetCertificates(repository),
        'project-1',
      );
      addTearDown(bloc.close);
      bloc.add(const CertificatesRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.certificates.single.recipient, 'Sara');
      repository.shouldFail = true;
      bloc.add(const CertificatesRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, CertificateLibraryStatus.failure);
    },
  );

  test(
    'VerificationBloc dispatches file, id and QR requests and handles failure',
    () async {
      final service = FakeVerificationService();
      final bloc = VerificationBloc(service);
      addTearDown(bloc.close);
      bloc.add(const VerifyCertificateId('certificate-1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, VerificationStatus.loaded);
      bloc.add(const VerifyQrPayload('cstudio://certificate-1'));
      await Future<void>.delayed(Duration.zero);
      expect(service.lastPayload, 'cstudio://certificate-1');
      bloc.add(
        VerifyCertificateFile(Uint8List.fromList([1]), 'certificate.pdf'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.lastFileName, 'certificate.pdf');
      service.shouldFail = true;
      bloc.add(const VerifyCertificateId('bad'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, VerificationStatus.failure);
    },
  );
}

class GetWorkspaceMetricsForTest extends GetWorkspaceMetrics {
  GetWorkspaceMetricsForTest(Future<WorkspaceMetrics> Function() action)
    : _action = action,
      super(_UnusedWorkspaceRepository());
  final Future<WorkspaceMetrics> Function() _action;
  @override
  Future<WorkspaceMetrics> call() => _action();
}

class _UnusedWorkspaceRepository implements WorkspaceRepository {
  @override
  Future<WorkspaceMetrics> getMetrics() => throw UnimplementedError();
}

class FakeInstitutionRepository implements InstitutionRepository {
  FakeInstitutionRepository({this.current});
  Institution? current;
  bool shouldFail = false;
  @override
  Future<Institution?> getCurrent() async {
    if (shouldFail) throw StateError('institution failed');
    return current;
  }

  @override
  Future<Institution> save(Institution value) async => current = value;
  @override
  Future<void> delete(String id) async => current = null;
}

class FakeImportRepository implements DataImportRepository {
  FakeImportRepository(this.result);
  final ImportedTable Function() result;
  @override
  ImportedTable parseTable(String rawText) => result();
  @override
  ImportedTable parseExcel(List<int> bytes) => result();
  @override
  Future<ImportedTable> saveForProject(String id, ImportedTable table) async =>
      table;
  @override
  Future<ImportedTable> getForProject(String id) async => result();
}

class FakeProjectRepository implements ProjectRepository {
  FakeProjectRepository(this.projects);
  List<Project> projects;
  @override
  Future<List<Project>> getAll({String? institutionId}) async => projects;
  @override
  Future<Project?> getById(String id) async =>
      projects.where((p) => p.id == id).firstOrNull;
  @override
  Future<Project> save(Project value) async {
    projects = [...projects, value];
    return value;
  }

  @override
  Future<void> delete(String id) async =>
      projects = projects.where((p) => p.id != id).toList();
  @override
  Future<void> deleteCascade(String id) => delete(id);
}

class FakeTemplateRepository implements TemplateRepository {
  FakeTemplateRepository(this.templates);
  List<TemplateAsset> templates;
  bool used = false;
  @override
  Future<List<TemplateAsset>> getAll() async => templates;
  @override
  Future<String?> selectedForProject(String id) async => null;
  @override
  Future<TemplateAsset> add(TemplateAsset value) async => value;
  @override
  Future<void> update(TemplateAsset value) async {}
  @override
  Future<void> selectForProject(String projectId, String templateId) async {}
  @override
  Future<bool> isUsedByProject(String id) async => used;
  @override
  Future<void> delete(String id) async {}
}

class FakeFontRepository implements FontRepository {
  FakeFontRepository(this.fonts);
  List<FontAsset> fonts;
  bool shouldFail = false;
  @override
  Future<List<FontAsset>> getAll() async {
    if (shouldFail) throw StateError('fonts failed');
    return fonts;
  }

  @override
  Future<String?> selectedForProject(String id) async => null;
  @override
  Future<FontAsset> add(FontAsset value, List<int> bytes) async => value;
  @override
  Future<void> selectForProject(String projectId, String fontId) async {}
  @override
  Future<void> delete(String id) async {}
}

class FakeCertificateRepository implements CertificateRepository {
  FakeCertificateRepository(this.certificates);
  final List<CertificateRecord> certificates;
  bool shouldFail = false;
  @override
  Future<List<CertificateRecord>> getAll({String? projectId}) async {
    if (shouldFail) throw StateError('certificates failed');
    return certificates;
  }
}

class FakeVerificationService
    implements CertificateVerificationServiceContract {
  bool shouldFail = false;
  String? lastPayload;
  String? lastFileName;
  CertificateVerificationResult get result =>
      const CertificateVerificationResult(
        status: CertificateVerificationStatus.valid,
        certificateId: 'certificate-1',
      );
  @override
  Future<CertificateVerificationResult> verify(String id) async {
    if (shouldFail) throw StateError('verification failed');
    return result;
  }

  @override
  Future<CertificateVerificationResult> verifyFile(
    List<int> bytes, {
    String? fileName,
  }) async {
    lastFileName = fileName;
    if (shouldFail) throw StateError('verification failed');
    return result;
  }

  @override
  Future<CertificateVerificationResult> verifyQr(String payload) async {
    lastPayload = payload;
    if (shouldFail) throw StateError('verification failed');
    return result;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}

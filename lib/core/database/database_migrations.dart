import 'database_tables.dart';

class DatabaseMigration {
  const DatabaseMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.statements,
    required this.description,
  });

  final int fromVersion;
  final int toVersion;
  final List<String> statements;
  final String description;
}

/// Ordered, append-only schema history.
///
/// Never edit the SQL of a migration that may already have shipped. Add a new
/// migration at the end instead. Version 0 is the empty database state; a new
/// database is created directly from [DatabaseSchema.createStatements].
abstract final class DatabaseMigrations {
  static const latestVersion = DatabaseSchema.version;

  static const migrations = <DatabaseMigration>[
    DatabaseMigration(
      fromVersion: 0,
      toVersion: 1,
      description: 'Initial offline certificate workspace schema',
      statements: [],
    ),
    DatabaseMigration(
      fromVersion: 1,
      toVersion: 2,
      description: 'Add document persistence and generation tracking',
      statements: [
        // v1 used the historical `students` terminology.
        'ALTER TABLE certificates ADD COLUMN document_json TEXT',
        '''CREATE TABLE generation_jobs (
          id TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          status TEXT NOT NULL,
          total_count INTEGER NOT NULL,
          completed_count INTEGER NOT NULL DEFAULT 0,
          failed_count INTEGER NOT NULL DEFAULT 0,
          started_at TEXT NOT NULL,
          completed_at TEXT,
          error_message TEXT
        )''',
        '''CREATE TABLE generation_items (
          id TEXT PRIMARY KEY,
          job_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          certificate_id TEXT,
          status TEXT NOT NULL,
          error_message TEXT,
          completed_at TEXT
        )''',
      ],
    ),
    DatabaseMigration(
      fromVersion: 2,
      toVersion: 3,
      description: 'Add query indexes for workspace and generation operations',
      statements: [
        'CREATE INDEX IF NOT EXISTS idx_projects_template ON projects (template_id)',
        'CREATE INDEX IF NOT EXISTS idx_certificate_fields_project ON certificate_fields (project_id)',
        'CREATE INDEX IF NOT EXISTS idx_signatures_project ON signatures (project_id)',
        'CREATE INDEX IF NOT EXISTS idx_generation_items_student ON generation_items (student_id)',
        'CREATE INDEX IF NOT EXISTS idx_verification_records_project ON verification_records (project_id)',
      ],
    ),
    DatabaseMigration(
      fromVersion: 3,
      toVersion: 4,
      description: 'Persist uploaded font bytes for portable offline rendering',
      statements: ['ALTER TABLE fonts ADD COLUMN font_bytes BLOB'],
    ),
    DatabaseMigration(
      fromVersion: 4,
      toVersion: 5,
      description: 'Rename student storage to neutral record terminology',
      statements: [
        'ALTER TABLE students RENAME TO records',
        'ALTER TABLE certificates RENAME COLUMN student_id TO record_id',
        'ALTER TABLE generation_items RENAME COLUMN student_id TO record_id',
        'DROP INDEX IF EXISTS idx_students_project',
        'DROP INDEX IF EXISTS idx_generation_items_student',
        'CREATE INDEX IF NOT EXISTS idx_records_project ON records (project_id)',
        'CREATE INDEX IF NOT EXISTS idx_generation_items_record ON generation_items (record_id)',
      ],
    ),
    DatabaseMigration(
      fromVersion: 5,
      toVersion: 6,
      description:
          'Distinguish visual signature assets from cryptographic signatures',
      statements: [
        'ALTER TABLE signatures RENAME TO signature_assets',
        'DROP INDEX IF EXISTS idx_signatures_project',
        'CREATE INDEX IF NOT EXISTS idx_signature_assets_project ON signature_assets (project_id)',
      ],
    ),
    DatabaseMigration(
      fromVersion: 6,
      toVersion: 7,
      description:
          'Remove unused visual-signature storage and normalize foreign keys',
      // SQLite requires table rebuilds to change foreign-key targets. The
      // adapter performs this migration atomically after inspecting the
      // existing schema; keeping the SQL here empty prevents unsafe replay.
      statements: [],
    ),
    DatabaseMigration(
      fromVersion: 7,
      toVersion: 8,
      description:
          'Denormalize project layout and mapping; remove generation history',
      statements: [],
    ),
    DatabaseMigration(
      fromVersion: 8,
      toVersion: 9,
      description: 'Link certificate fields to their selected font asset',
      statements: [],
    ),
    DatabaseMigration(
      fromVersion: 9,
      toVersion: 10,
      description: 'Persist imported record column definitions',
      statements: ['ALTER TABLE records ADD COLUMN columns_json TEXT'],
    ),
  ];

  static Iterable<DatabaseMigration> pendingFrom(int currentVersion) sync* {
    for (final migration in migrations) {
      if (migration.fromVersion >= currentVersion &&
          migration.toVersion <= latestVersion) {
        yield migration;
      }
    }
  }

  static List<String> statementsForUpgrade(int currentVersion) {
    if (currentVersion < 0 || currentVersion > latestVersion) {
      throw ArgumentError.value(
        currentVersion,
        'currentVersion',
        'Unsupported database version.',
      );
    }

    // Version 0 is the empty state. Bootstrap with the complete, current
    // schema rather than replaying historical migrations against new data.
    if (currentVersion == 0) {
      return [...DatabaseSchema.createStatements, ...DatabaseSchema.indexes];
    }

    return [
      for (final migration in pendingFrom(currentVersion))
        ...migration.statements,
    ];
  }
}

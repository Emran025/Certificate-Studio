import 'database_tables.dart';

class DatabaseMigration {
  const DatabaseMigration({required this.fromVersion, required this.toVersion, required this.statements});

  final int fromVersion;
  final int toVersion;
  final List<String> statements;
}

abstract final class DatabaseMigrations {
  static const latestVersion = DatabaseSchema.version;

  static const migrations = <DatabaseMigration>[
    DatabaseMigration(
      fromVersion: 0,
      toVersion: 1,
      statements: [
        ...DatabaseSchema.createStatements,
        ...DatabaseSchema.indexes,
      ],
    ),
    DatabaseMigration(
      fromVersion: 1,
      toVersion: 2,
      statements: [
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
  ];

  static List<String> statementsForUpgrade(int currentVersion) {
    if (currentVersion < 0 || currentVersion > latestVersion) {
      throw ArgumentError.value(currentVersion, 'currentVersion', 'Unsupported database version.');
    }

    // A fresh database uses the complete current schema. Incremental
    // migrations are only for databases that already have version one.
    if (currentVersion == 0) {
      return [...DatabaseSchema.createStatements, ...DatabaseSchema.indexes];
    }

    return [
      for (final migration in migrations)
        if (migration.fromVersion >= currentVersion && migration.toVersion <= latestVersion)
          ...migration.statements,
    ];
  }
}

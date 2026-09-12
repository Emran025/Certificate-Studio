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
  ];

  static List<String> statementsForUpgrade(int currentVersion) {
    if (currentVersion < 0 || currentVersion > latestVersion) {
      throw ArgumentError.value(currentVersion, 'currentVersion', 'Unsupported database version.');
    }

    return [
      for (final migration in migrations)
        if (migration.fromVersion >= currentVersion && migration.toVersion <= latestVersion)
          ...migration.statements,
    ];
  }
}

/// Canonical names for every persisted table.
///
abstract final class DatabaseTables {
  static const institutions = 'institutions';
  static const projects = 'projects';
  static const templates = 'templates';
  static const fonts = 'fonts';
  static const records = 'records';
  static const certificateFields = 'certificate_fields';
  static const certificateLayouts = 'certificate_layouts';
  static const certificates = 'certificates';
  static const generationJobs = 'generation_jobs';
  static const generationItems = 'generation_items';
  static const verificationRecords = 'verification_records';
  static const settings = 'settings';

  static const all = <String>[
    institutions,
    projects,
    templates,
    fonts,
    records,
    certificateFields,
    certificateLayouts,
    certificates,
    generationJobs,
    generationItems,
    verificationRecords,
    settings,
  ];
}

abstract final class DatabaseSchema {
  /// Version 7 is the canonical schema for the currently implemented domain.
  static const version = 7;

  /// The complete schema used for a new database. Existing databases must use
  /// [DatabaseMigrations] instead of replaying this list.
  static const createStatements = <String>[
    '''CREATE TABLE institutions (
      id TEXT PRIMARY KEY,
      institution_id TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      name_ar TEXT,
      name_en TEXT,
      logo_path TEXT,
      contact_json TEXT,
      settings_json TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE projects (
      id TEXT PRIMARY KEY,
      institution_id TEXT NOT NULL,
      name TEXT NOT NULL,
      course_name TEXT,
      description TEXT,
      start_date TEXT,
      end_date TEXT,
      trainer_name TEXT,
      organization_name TEXT,
      logo_path TEXT,
      template_id TEXT,
      settings_json TEXT,
      project_key_reference TEXT NOT NULL,
      version INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
      FOREIGN KEY (institution_id) REFERENCES institutions (id),
      FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE SET NULL
    )''',
    '''CREATE TABLE templates (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      file_path TEXT NOT NULL,
      width INTEGER NOT NULL,
      height INTEGER NOT NULL,
      dpi REAL NOT NULL,
      format TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE fonts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      family TEXT NOT NULL,
      file_path TEXT NOT NULL,
      format TEXT NOT NULL,
      font_bytes BLOB,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE records (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      class_name TEXT NOT NULL,
      data_json TEXT NOT NULL,
      row_number INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (project_id) REFERENCES projects (id)
    )''',
    '''CREATE TABLE certificate_fields (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      class_name TEXT NOT NULL,
      source TEXT,
      position_json TEXT NOT NULL,
      style_json TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (project_id) REFERENCES projects (id)
    )''',
    '''CREATE TABLE certificate_layouts (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL UNIQUE,
      canvas_width REAL NOT NULL,
      canvas_height REAL NOT NULL,
      grid_enabled INTEGER NOT NULL DEFAULT 1,
      settings_json TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (project_id) REFERENCES projects (id)
    )''',
    '''CREATE TABLE certificates (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      record_id TEXT NOT NULL,
      file_path TEXT,
      image_path TEXT,
      document_json TEXT,
      status TEXT NOT NULL,
      document_hash TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (project_id) REFERENCES projects (id),
      FOREIGN KEY (record_id) REFERENCES records (id)
    )''',
    '''CREATE TABLE generation_jobs (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      status TEXT NOT NULL,
      total_count INTEGER NOT NULL,
      completed_count INTEGER NOT NULL DEFAULT 0,
      failed_count INTEGER NOT NULL DEFAULT 0,
      started_at TEXT NOT NULL,
      completed_at TEXT,
      error_message TEXT,
      FOREIGN KEY (project_id) REFERENCES projects (id)
    )''',
    '''CREATE TABLE generation_items (
      id TEXT PRIMARY KEY,
      job_id TEXT NOT NULL,
      record_id TEXT NOT NULL,
      certificate_id TEXT,
      status TEXT NOT NULL,
      error_message TEXT,
      completed_at TEXT,
      FOREIGN KEY (job_id) REFERENCES generation_jobs (id),
      FOREIGN KEY (record_id) REFERENCES records (id),
      FOREIGN KEY (certificate_id) REFERENCES certificates (id)
    )''',
    '''CREATE TABLE verification_records (
      id TEXT PRIMARY KEY,
      certificate_id TEXT NOT NULL UNIQUE,
      institution_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      payload_json TEXT NOT NULL,
        signature TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (certificate_id) REFERENCES certificates (id),
      FOREIGN KEY (institution_id) REFERENCES institutions (id),
      FOREIGN KEY (project_id) REFERENCES projects (id)
    )''',
    '''CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value_json TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''',
  ];

  static const indexes = <String>[
    'CREATE INDEX idx_projects_institution ON projects (institution_id)',
    'CREATE INDEX idx_projects_template ON projects (template_id)',
    'CREATE INDEX idx_records_project ON records (project_id)',
    'CREATE INDEX idx_certificate_fields_project ON certificate_fields (project_id)',
    'CREATE INDEX idx_certificates_project ON certificates (project_id)',
    'CREATE INDEX idx_certificates_status ON certificates (status)',
    'CREATE INDEX idx_generation_jobs_project ON generation_jobs (project_id)',
    'CREATE INDEX idx_generation_items_job ON generation_items (job_id)',
    'CREATE INDEX idx_generation_items_record ON generation_items (record_id)',
    'CREATE INDEX idx_verification_records_project ON verification_records (project_id)',
  ];
}

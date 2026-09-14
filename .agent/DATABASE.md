# Certificate Studio — Database Architecture & Schema Specification

## 1. Purpose

This document defines the database architecture, entities, relationships, constraints, lifecycle rules, indexing strategy, persistence boundaries, and migration requirements for Certificate Studio.

The database is responsible for storing the **structured state of the application**.

It must not become the storage layer for every type of binary asset.

The database stores metadata and structured information, while large or binary resources such as templates, fonts, signatures, generated certificates, and project packages should be stored through the application's file/storage abstraction and referenced by stable identifiers.

The database design must support:

* Offline-first operation
* Multiple institutions
* Multiple certificate projects
* Reusable templates
* Reusable fonts
* Recipient/student data
* Certificate field definitions
* Field-to-data mappings
* Certificate layouts
* Signatures and stamps
* Cryptographic identities and key metadata
* Certificate generation jobs
* Generated certificate metadata
* Export jobs
* Verification records
* Project package import/export
* Application settings
* Future schema migrations
* Future synchronization without redesigning the domain model

---

# 2. Database Design Principles

## 2.1 Local-first

The database is primarily a local database.

The initial implementation must not require a remote server for normal application operation.

---

## 2.2 Domain-driven structure

Database entities must correspond to meaningful domain concepts rather than UI screens.

For example:

```text
Project
Template
Recipient
Certificate
Generation Job
```

are domain concepts.

A widget state such as:

```text
DesignerSelectedField
```

must not become a database table merely because it exists in the UI.

---

## 2.3 Database stores structured state

The database should store:

* IDs
* relationships
* metadata
* configuration
* structured project state
* indexes
* statuses
* timestamps
* version information

Large binary files should normally remain outside the relational database.

---

## 2.4 Stable identifiers

Every persistent entity must have a stable unique identifier.

Prefer UUID/ULID-style identifiers rather than relying exclusively on auto-increment integers.

The identifier must remain stable when:

* a project is exported
* a project is imported
* records are regenerated
* data is migrated
* synchronization is introduced later

---

## 2.5 Timestamps

Persistent entities should generally include:

```text
created_at
updated_at
```

Entities with lifecycle state should additionally include relevant timestamps such as:

```text
deleted_at
generated_at
verified_at
completed_at
```

Timestamps must use a consistent UTC representation internally.

The UI may convert timestamps to the local timezone.

---

# 3. Database Technology

The local relational database uses a file-backed SQLite database encrypted with
SQLCipher. The SQLCipher driver, database path, key application, and
platform-specific runtime details are isolated inside the core database
adapter.

The application must access SQLCipher through a repository/data-source
abstraction.

The domain layer must not depend directly on SQLite APIs.

Conceptually:

```text
Domain
  ↓
Repository Interface
  ↓
Data Layer
  ↓
  SQLCipher Implementation
```

For platforms where traditional SQLite access is not appropriate, an alternative persistence implementation may be provided while preserving the same domain/repository contracts.

---

# 4. Persistence Boundaries

The application has four main persistence categories.

```text
┌──────────────────────────────────────────┐
│ SQLite Database                          │
│                                          │
│ Structured metadata and application state│
└──────────────────────┬───────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────┐
│ Local File Storage                       │
│                                          │
│ Templates / Fonts / Signatures / Output  │
└──────────────────────┬───────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────┐
│ Project Package                          │
│                                          │
│ Portable project representation          │
└──────────────────────────────────────────┘
```

The database is not itself the portable project package.

The project package is a higher-level export format that collects the required project state and referenced resources.

---

# 5. Entity Overview

The primary database entities are:

```text
Institution
InstitutionKey
Project
ProjectKey
Template
ProjectTemplate
Font
ProjectFont
SignatureAsset
ProjectSignature
Recipient
RecipientFieldValue
FieldDefinition
FieldStyle
FieldMapping
Layout
LayoutField
Certificate
GenerationJob
GenerationItem
ExportJob
VerificationRecord
ProjectPackage
ApplicationSetting
```

Some of these may be represented through JSON/configuration columns where appropriate, but the logical entities and ownership relationships must remain clear.

---

# 6. Entity Relationship Overview

High-level relationship:

```text
Institution
   │
   ├───────────────┐
   │               │
   ▼               ▼
InstitutionKey   Project
                   │
       ┌───────────┼───────────────┐
       │           │               │
       ▼           ▼               ▼
    Template      Layout        ProjectKey
       │           │
       │           ▼
       │      FieldDefinition
       │           │
       │           ▼
       │      FieldMapping
       │
       ▼
   ProjectTemplate

Project
   │
   ├── ProjectFont
   ├── ProjectSignature
   ├── Recipient
   ├── Certificate
   ├── GenerationJob
   ├── ExportJob
   └── ProjectPackage

Recipient
   │
   └── Certificate

Certificate
   ├── GenerationItem
   └── VerificationRecord
```

---

# 7. Naming Conventions

Database naming must follow these rules:

* Table names: `snake_case`
* Column names: `snake_case`
* Primary key: `id`
* Foreign keys: `<entity>_id`
* Timestamp columns: `<event>_at`
* Boolean columns: `is_*` or `has_*`
* Status values: controlled application/domain enums
* Index names: descriptive and deterministic

Example:

```text
project_id
created_at
updated_at
is_active
verification_status
```

---

# 8. Institution

The institution represents the certificate issuer.

### Table

```text
institutions
```

### Fields

```text
id
name
identifier
description
logo_asset_id
contact_email
contact_phone
address
metadata_json
is_active
created_at
updated_at
```

### Purpose

An institution owns certificate projects and provides the issuer identity used by certificate verification.

---

# 9. Institution Keys

Cryptographic identities must be represented separately from the institution record.

### Table

```text
institution_keys
```

### Fields

```text
id
institution_id
key_identifier
algorithm
public_key
private_key_reference
key_version
status
created_at
activated_at
rotated_at
revoked_at
```

The private key itself should not be stored as unrestricted plaintext in the database.

`private_key_reference` should point to the secure key-storage mechanism or an encrypted key representation.

The database stores key metadata and lifecycle information.

---

# 10. Project

The project is the primary workspace.

### Table

```text
projects
```

### Fields

```text
id
institution_id
name
identifier
description
certificate_type
status
project_version
default_template_id
active_key_id
configuration_json
created_at
updated_at
archived_at
```

### Project status

Example domain values:

```text
draft
ready
generating
generated
archived
```

The exact enum may evolve, but database values must be controlled by the domain layer.

---

# 11. Project Keys

A project may have its own cryptographic identity or project-specific cryptographic configuration.

### Table

```text
project_keys
```

### Fields

```text
id
project_id
key_identifier
algorithm
public_key
private_key_reference
key_version
status
created_at
activated_at
rotated_at
revoked_at
```

A project key must remain associated with its project lifecycle.

Key rotation must not destroy historical key metadata required to verify previously issued certificates.

---

# 12. Templates

Templates represent reusable certificate backgrounds/design resources.

### Table

```text
templates
```

### Fields

```text
id
name
description
asset_path
asset_hash
mime_type
width
height
resolution
metadata_json
created_at
updated_at
```

The actual template binary should normally reside in local file storage.

`asset_hash` allows the application to detect accidental or unauthorized changes.

---

# 13. Project Templates

A project may use a reusable template.

### Table

```text
project_templates
```

### Fields

```text
id
project_id
template_id
role
version
created_at
```

`role` may initially contain:

```text
primary
```

The abstraction allows future support for:

* front
* back
* alternate
* page background

without redesigning the project model.

---

# 14. Fonts

Fonts are reusable application resources.

### Table

```text
fonts
```

### Fields

```text
id
name
family_name
file_name
asset_path
asset_hash
format
weight
style
version
metadata_json
created_at
updated_at
```

The actual font file is stored through the file-storage abstraction.

---

# 15. Project Fonts

A project explicitly declares the fonts it depends on.

### Table

```text
project_fonts
```

### Fields

```text
id
project_id
font_id
role
is_required
created_at
```

This is essential for project portability.

When exporting a project, the project package can determine exactly which fonts must be included.

---

# 16. Signature Assets

Visual signatures and stamps are stored as reusable assets.

### Table

```text
signature_assets
```

### Fields

```text
id
name
asset_path
asset_hash
asset_type
mime_type
metadata_json
created_at
updated_at
```

`asset_type` may include:

```text
signature
stamp
seal
```

---

# 17. Project Signatures

A project can use one or more signature assets.

### Table

```text
project_signatures
```

### Fields

```text
id
project_id
signature_asset_id
role
label
created_at
```

---

# 18. Layouts

The certificate design should be represented separately from the project itself.

### Table

```text
layouts
```

### Fields

```text
id
project_id
name
version
canvas_width
canvas_height
coordinate_system
configuration_json
created_at
updated_at
```

A project may eventually contain multiple layouts.

Examples:

```text
default
landscape
portrait
alternate
```

---

# 19. Field Definitions

A certificate field represents a visual element on the certificate.

### Table

```text
field_definitions
```

### Fields

```text
id
layout_id
field_key
field_type
label
data_source
z_index
is_visible
is_locked
is_required
configuration_json
created_at
updated_at
```

### Field types

Initial examples:

```text
text
data
image
signature
stamp
qr
shape
```

Additional field types may be introduced later.

---

# 20. Field Style

Visual styling can be represented either as structured columns or a versioned configuration object.

Recommended approach:

Use a dedicated style record when the style is frequently queried or independently manipulated.

### Table

```text
field_styles
```

### Fields

```text
id
field_id
font_id
font_size
font_weight
font_style
text_color
opacity
alignment
text_direction
overflow_mode
line_height
letter_spacing
configuration_json
created_at
updated_at
```

The style must remain independent from recipient-specific values.

---

# 21. Field Mapping

A field mapping connects a visual certificate field to a source data field.

### Table

```text
field_mappings
```

### Fields

```text
id
project_id
field_id
source_type
source_key
transform
default_value
is_required
validation_rules_json
created_at
updated_at
```

Example:

```text
field_id:
    recipient_name_field

source_type:
    recipient_column

source_key:
    student_name
```

The mapping layer must remain independent from the Excel implementation.

The original source may be Excel, clipboard data, imported project data, or a future remote data source.

---

# 22. Recipients

Recipients represent people or entities receiving certificates.

### Table

```text
recipients
```

### Fields

```text
id
project_id
external_identifier
name
phone
email
status
source_row_number
metadata_json
created_at
updated_at
```

The application should not assume that all projects require:

* phone
* email
* external identifier

These fields are optional unless required by project configuration.

---

# 23. Recipient Field Values

Because imported Excel data may contain arbitrary columns, the schema should not create a new SQL column for every spreadsheet column.

Instead, dynamic source data should be represented through a structured value store.

### Table

```text
recipient_field_values
```

### Fields

```text
id
recipient_id
field_key
value_text
value_type
normalized_value
created_at
updated_at
```

Examples:

```text
student_name
course
grade
date
instructor
phone
```

This allows each project to import arbitrary spreadsheet structures without changing the database schema.

---

# 24. Source Data Imports

Imported files should be tracked independently from recipients.

### Table

```text
data_imports
```

### Fields

```text
id
project_id
source_type
source_name
source_path
source_hash
row_count
column_count
status
imported_at
created_at
```

Source types may include:

```text
excel
clipboard
csv
project
manual
```

This provides traceability without forcing the application to retain the original source file permanently.

---

# 25. Certificates

A certificate represents a generated certificate instance.

### Table

```text
certificates
```

### Fields

```text
id
project_id
recipient_id
certificate_number
certificate_hash
signature
signing_key_id
status
generation_version
layout_version
issued_at
generated_at
revoked_at
created_at
updated_at
metadata_json
```

### Certificate status

Possible values:

```text
draft
generated
issued
revoked
invalid
```

The certificate record should remain even if the physical PDF or image output is deleted.

---

# 26. Certificate Files

Generated PDF/image files should be tracked separately from the certificate entity.

### Table

```text
certificate_files
```

### Fields

```text
id
certificate_id
file_type
file_path
file_hash
mime_type
file_size
resolution
created_at
updated_at
```

Possible file types:

```text
pdf
image
```

This allows one certificate to have multiple output representations.

---

# 27. Generation Jobs

Batch generation is an asynchronous operation from the user's perspective.

### Table

```text
generation_jobs
```

### Fields

```text
id
project_id
status
total_items
completed_items
successful_items
failed_items
configuration_json
started_at
completed_at
created_at
updated_at
```

Possible statuses:

```text
queued
running
completed
completed_with_errors
failed
cancelled
```

---

# 28. Generation Items

Each recipient within a generation job should have an individual job record.

### Table

```text
generation_items
```

### Fields

```text
id
generation_job_id
recipient_id
certificate_id
status
error_code
error_message
started_at
completed_at
created_at
updated_at
```

This allows partial success.

For example:

```text
42 recipients

38 successful
4 failed
```

The application can retry only failed items without regenerating successful certificates.

---

# 29. Export Jobs

Export operations should be represented separately from certificate generation.

### Table

```text
export_jobs
```

### Fields

```text
id
project_id
status
export_type
output_path
configuration_json
total_items
completed_items
error_message
started_at
completed_at
created_at
updated_at
```

Export types may include:

```text
single
batch
zip
project
```

---

# 30. Verification Records

Verification operations should be auditable locally.

### Table

```text
verification_records
```

### Fields

```text
id
certificate_id
verification_method
verification_status
certificate_hash
signature_valid
integrity_valid
issuer_valid
verification_message
metadata_json
verified_at
created_at
```

Verification methods may include:

```text
pdf
image
qr
certificate_id
```

Possible verification statuses:

```text
valid
invalid
unknown
unsupported
tampered
revoked
```

---

# 31. Project Packages

Imported/exported project packages can be tracked.

### Table

```text
project_packages
```

### Fields

```text
id
project_id
package_identifier
package_version
format_version
file_path
file_hash
operation
status
created_at
completed_at
```

Operations may include:

```text
export
import
```

This record is metadata about package operations.

The package itself remains a file-system artifact.

---

# 32. Application Settings

Application-wide settings should not be scattered across unrelated tables.

### Table

```text
application_settings
```

### Fields

```text
key
value
value_type
updated_at
```

Examples:

```text
theme
language
default_export_format
default_filename_pattern
default_output_directory
```

Sensitive secrets must not be stored as ordinary application settings.

---

# 33. Database Migrations

The schema must be versioned.

Every structural change requires a migration.

Example:

```text
001_initial_schema
002_add_project_keys
003_add_certificate_files
004_add_verification_records
005_add_project_packages
```

Migrations must be:

* Ordered
* Repeatable
* Testable
* Forward-compatible where possible
* Applied automatically during application startup when required

The application must never silently modify production schema without a migration.

---

# 34. Foreign Key Rules

Foreign key constraints must be enabled.

General relationship rules:

```text
Institution
    ↓
Project
```

Deleting an institution should not automatically destroy all historical certificate records without an explicit domain operation.

For project-owned records, cascading deletion may be appropriate for temporary/configuration data.

However, certificate records and cryptographic metadata must be handled deliberately.

The database design must distinguish between:

### Owned configuration

Safe to cascade.

Examples:

```text
Project
 → Field Definitions
 → Field Mappings
 → Layout Fields
```

### Historical/security records

Require explicit lifecycle handling.

Examples:

```text
Certificate
Institution Key
Verification Record
```

---

# 35. Soft Deletion

Soft deletion should be used only where it provides real domain value.

It should not be added mechanically to every table.

Suitable examples include:

```text
projects
templates
fonts
signature_assets
```

where restoration or historical references may matter.

Historical certificate records should generally not be physically deleted merely because their associated UI object is hidden.

---

# 36. Indexing Strategy

Indexes must be created according to actual access patterns.

Important indexes include:

```text
projects(institution_id)
projects(status)

project_templates(project_id)
project_fonts(project_id)
project_signatures(project_id)

layouts(project_id)

field_definitions(layout_id)
field_mappings(project_id, field_id)

recipients(project_id)
recipients(project_id, name)

recipient_field_values(recipient_id, field_key)

certificates(project_id)
certificates(recipient_id)
certificates(certificate_number)
certificates(certificate_hash)
certificates(status)

certificate_files(certificate_id)

generation_jobs(project_id, status)
generation_items(generation_job_id, status)

export_jobs(project_id, status)

verification_records(certificate_id)
verification_records(verification_status)
```

Indexes must be evaluated using actual query plans as the dataset grows.

---

# 37. Uniqueness Constraints

The following values should normally be unique within their appropriate scope.

Examples:

```text
projects:
    (institution_id, identifier)

certificates:
    (project_id, certificate_number)

field_definitions:
    (layout_id, field_key)

field_mappings:
    (project_id, field_id)

project_fonts:
    (project_id, font_id)

project_signatures:
    (project_id, signature_asset_id)
```

The exact uniqueness policy must be enforced at the database level where possible.

---

# 38. JSON Usage

JSON/configuration columns may be used for data that is:

* Highly variable
* Versioned
* Renderer-specific
* Platform-specific
* Not commonly queried
* Naturally represented as a configuration object

Examples:

```text
metadata_json
configuration_json
validation_rules_json
```

However, JSON must not be used as an excuse to put the entire relational model into one column.

Frequently queried relationships and domain properties should remain structured relational data.

---

# 39. Binary Asset Storage

Binary resources should normally be stored through the application's file-storage abstraction.

Examples:

```text
Template image
Font file
Signature image
Generated PDF
Generated image
Project package
```

Database records should store:

```text
asset identifier
path/reference
hash
mime type
size
metadata
```

Example:

```text
templates
    id
    asset_path
    asset_hash
    mime_type
```

This prevents the SQLite database from becoming unnecessarily large and simplifies project export/import.

---

# 40. Asset Integrity

Important assets should have a cryptographic hash.

Examples:

```text
template.asset_hash
font.asset_hash
signature.asset_hash
certificate_file.file_hash
```

When loading an asset, the application can optionally verify that the file still corresponds to its registered hash.

---

# 41. Certificate Versioning

Certificate generation must be reproducible.

A certificate should therefore retain enough information to identify:

```text
project version
layout version
generation version
signing key version
```

This prevents future changes from making historical certificates ambiguous.

Example:

```text
Certificate
 ├── Project Version: 3
 ├── Layout Version: 7
 ├── Generation Version: 2
 └── Signing Key Version: 4
```

---

# 42. Immutability of Issued Certificates

Once a certificate is issued and cryptographically signed, its historical representation should be treated as immutable.

If the source project changes:

```text
Do not silently modify the existing issued certificate.
```

Instead:

```text
Original Certificate
        ↓
Remain historically valid
```

and a new generation may produce:

```text
New Certificate
        ↓
New hash
New signature
New generation metadata
```

If revocation is supported, revocation should be represented explicitly.

---

# 43. Certificate IDs

Every generated certificate must have a stable certificate identifier.

The identifier should be:

* Unique
* Non-ambiguous
* Safe to place in a QR code
* Safe to display to users
* Independent of the physical filename

Example conceptual format:

```text
CERT-2026-000001
```

The implementation may use a different scheme as long as uniqueness and stability are preserved.

The certificate ID must not be used as the cryptographic signature itself.

---

# 44. Verification Data

Verification metadata should be represented independently from the visual certificate.

The certificate can contain:

```text
Certificate ID
Institution ID
Project ID
Hash
Signature metadata
Key identifier
Verification version
```

This information may be encoded into a QR code or embedded into supported document metadata.

The verification protocol must be versioned.

Example:

```text
verification_version = 1
```

Future protocol changes must not make previously issued certificates impossible to interpret.

---

# 45. Project Export Requirements

When a project is exported, the package builder must determine its complete dependency graph.

Conceptually:

```text
Project
 ├── Template
 ├── Fonts
 ├── Signatures
 ├── Layout
 ├── Fields
 ├── Mappings
 ├── Security configuration
 └── Project metadata
```

The package must not rely on absolute operating-system paths.

All internal references must be portable.

---

# 46. Import Requirements

When importing a project package:

1. Validate package format.
2. Validate package version.
3. Validate manifest.
4. Validate required resources.
5. Validate hashes.
6. Validate internal references.
7. Validate project schema.
8. Detect conflicts with existing resources.
9. Migrate old project versions if required.
10. Insert the project into the local database.
11. Register imported assets.
12. Rebuild indexes/references where required.

An invalid package must not partially corrupt the local database.

The import operation should be transactional.

---

# 47. Transaction Requirements

Transactions must be used for operations that modify multiple related records.

Examples:

### Project creation

```text
Create Project
+
Create Project Configuration
+
Attach Template
+
Attach Fonts
+
Create Layout
```

### Certificate generation result

```text
Create Certificate
+
Create Certificate Files
+
Update Generation Item
```

### Project import

```text
Import Project
+
Import Resources
+
Create Database Records
+
Create Relationships
```

If any critical operation fails, the transaction should roll back.

---

# 48. Concurrency and Jobs

Generation and export operations may run asynchronously.

The database must therefore represent job state independently from UI state.

The UI can subscribe to job progress through the application layer.

Example:

```text
Database
    ↓
Generation Job
    ↓
Application Service
    ↓
BLoC/Cubit
    ↓
Progress UI
```

The database must not contain transient UI state merely to make progress bars work.

---

# 49. Search Strategy

The application should support efficient local search for:

* Projects
* Recipients
* Certificates
* Templates
* Fonts

Search should be implemented according to actual requirements.

For small datasets, ordinary SQL `LIKE`/indexed queries may be sufficient.

For larger datasets, SQLite full-text search can be introduced without changing the domain model.

---

# 50. Audit Considerations

The initial implementation does not require a full enterprise audit-log system.

However, the architecture should leave room for future audit records.

Potential future table:

```text
audit_events
```

Possible fields:

```text
id
project_id
actor_type
actor_id
action
entity_type
entity_id
metadata_json
created_at
```

This can later support:

* Human activity tracking
* Security events
* Certificate lifecycle tracking
* Administrative auditing

It should not be implemented merely for the sake of adding tables unless the feature is required.

---

# 51. Data Retention

The application should distinguish between:

### Configuration data

Can be replaced or removed.

### Generated output

Can be regenerated depending on project state.

### Issued certificate records

May need long-term preservation.

### Cryptographic key history

Must be preserved as necessary to verify historical certificates.

Deleting a project must therefore be treated as a domain operation rather than a simple SQL `DELETE`.

---

# 52. Privacy

Recipient information may contain personal data.

The database design should therefore:

* Minimize unnecessary personal information.
* Store only required recipient fields.
* Protect local database access.
* Protect sensitive key material separately.
* Avoid placing personal information unnecessarily into logs.
* Avoid exposing recipient data through diagnostics.
* Support secure deletion where required.

---

# 53. Backup and Recovery

The application should eventually support local backup/recovery.

Backup should distinguish between:

```text
Database
+
Asset Storage
+
Cryptographic Key Material
```

A database-only backup is not sufficient to reconstruct a complete project if assets are stored externally.

The preferred future approach is a consistent application backup or project package mechanism that preserves required relationships.

---

# 54. Database Does Not Define the Certificate Format

The relational database is an implementation detail.

The certificate itself must have an independent conceptual format.

Therefore:

```text
Database Schema
        ≠
Certificate Format
```

A certificate should remain verifiable even if its originating SQLite database is unavailable, provided the certificate contains or has access to the required verification information.

This is a fundamental architectural requirement.

---

# 55. Offline Verification

Offline verification should rely on information that can be available locally.

Conceptually:

```text
Certificate
    ↓
Extract Verification Metadata
    ↓
Resolve Issuer / Key
    ↓
Calculate Hash
    ↓
Verify Signature
    ↓
Verification Result
```

The database may assist by providing:

* Known institutions
* Public keys
* Certificate records
* Revocation information
* Project metadata

However, the certificate must not become unverifiable simply because the original project database is unavailable.

---

# 56. Future Synchronization

The schema should remain compatible with future synchronization.

This means:

* Stable IDs
* Explicit timestamps
* Version fields
* Avoiding implicit database-generated identity as the only identity
* Clear ownership relationships
* Deterministic project/package representation
* Explicit conflict-sensitive entities

Synchronization is not part of the initial implementation.

The database must simply avoid architectural decisions that make future synchronization impossible.

---

# 57. Initial Schema Scope

The first database implementation should prioritize the following tables:

```text
institutions
institution_keys

projects
project_keys

templates
project_templates

fonts
project_fonts

signature_assets
project_signatures

layouts
field_definitions
field_styles
field_mappings

recipients
recipient_field_values
data_imports

certificates
certificate_files

generation_jobs
generation_items

export_jobs

verification_records

project_packages

application_settings
```

Additional tables must only be introduced when a real domain requirement exists.

---

# 58. Implementation Priority

Recommended implementation order:

```text
Phase 1
────────
Database infrastructure
Migration system
Institutions
Projects
Settings

Phase 2
────────
Templates
Fonts
Signatures
Layouts
Fields
Mappings

Phase 3
────────
Recipients
Imported data
Dynamic field values

Phase 4
────────
Certificates
Certificate files
Generation jobs
Generation items

Phase 5
────────
Exports
Verification
Project packages

Phase 6
────────
Advanced security
Key rotation
Audit
Backup
Future synchronization
```

---

# 59. Required Database Guarantees

The implementation is considered correct only when it guarantees:

1. Every persistent entity has a stable ID.
2. Foreign-key relationships are enforced.
3. Schema changes are migrated.
4. Project data is isolated between projects.
5. Historical certificate records remain identifiable.
6. Issued certificates are not silently mutated.
7. Cryptographic key history can be preserved.
8. Dynamic spreadsheet columns do not require schema changes.
9. Binary assets are not unnecessarily embedded in SQLite.
10. Project packages can reconstruct the required project state.
11. Database transactions protect multi-record operations.
12. Certificate verification does not fundamentally depend on the original SQLite database.
13. The schema can evolve without breaking existing projects.
14. The domain layer remains independent from SQLite implementation details.

---

# 60. Important Architectural Rule

The database must represent the **state of the certificate system**, not the implementation details of the Flutter UI.

Do not create database tables merely because a Flutter screen, widget, BLoC, event, or state exists.

The correct dependency direction is:

```text
UI
 ↓
Application / Domain
 ↓
Repository
 ↓
Database
```

Never:

```text
Database
 ↓
UI implementation
```

The database schema must remain stable even if the UI is redesigned.

---

# 61. Final Conceptual Model

The complete persistent model can be summarized as:

```text
                         INSTITUTION
                              │
                  ┌───────────┴───────────┐
                  │                       │
             Institution Key           PROJECT
                                          │
             ┌────────────────────────────┼────────────────────────────┐
             │                            │                            │
             ▼                            ▼                            ▼
         Resources                     DESIGN                       SECURITY
             │                            │                            │
     ┌───────┼────────┐          ┌────────┼────────┐              Project Key
     ▼       ▼        ▼          ▼        ▼        ▼
 Template  Font   Signature    Layout   Fields   Mapping
                                          │
                                          ▼
                                      RECIPIENTS
                                          │
                                          ▼
                                     CERTIFICATES
                                          │
                          ┌───────────────┼───────────────┐
                          ▼               ▼               ▼
                    Certificate      Generation        Verification
                       Files           Jobs              Records
                          │
                          ▼
                       EXPORTS
```

The database is therefore the persistent foundation of the application, while the rendering engine, cryptographic engine, file-storage layer, project-package system, and Flutter UI remain independent subsystems built around this persistent model.

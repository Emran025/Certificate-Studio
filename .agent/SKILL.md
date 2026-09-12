---
name: certificate-studio
description: >-
  Complete operational guide for Certificate Studio — a cross-platform,
  offline-first Flutter application for designing, generating, managing,
  and cryptographically verifying institutional certificates.
  Activate this skill whenever working on any part of this codebase.
---

# Certificate Studio — AI Agent Operating Guide

This document is the **primary context file** for any AI agent working on the
Certificate Studio project. Read it fully before making architectural decisions,
writing code, or suggesting changes.

---

## 1. Project Identity

| Property | Value |
|---|---|
| **Name** | Certificate Studio |
| **Type** | Cross-platform Flutter application |
| **Architecture** | Modular Clean Architecture + BLoC |
| **Primary Targets** | Windows Desktop, Android, Linux, macOS, iOS, Web |
| **Core Principle** | Offline-first — internet is optional, never required |
| **Language** | Dart (Flutter), with a Python reference package for cryptography |
| **State Management** | BLoC / Cubit |
| **Database** | SQLCipher (encrypted local database) |
| **Version** | 1.0.0 (active development) |

**One-line mission:**
> Design once. Generate many. Verify with confidence.

---

## 2. What This Application Does

Certificate Studio replaces the fragmented workflow of:

```
Design software + Spreadsheet + Manual scripting + PDF tools
+ Separate storage + Messaging + Custom verification
```

with a single integrated workspace:

```
Certificate Template
      +
Recipient Data (Excel / Paste)
      +
Visual Layout (Certificate Designer)
      +
Fonts and Signatures
      +
Security Metadata (Hash + Digital Signature + QR)
      down
Certificate Generation (PDF + High-Resolution Image)
      down
Certificate Library (Browse / Preview / Search)
      down
Export / Share / Verify
```

---

## 3. Core Domain Concepts

The agent must understand these domain concepts deeply.

### 3.1 Certificate Project

The **Project** is the central unit of the application.

A project is an isolated workspace for one certificate-issuing event:
- "Flutter Advanced Course 2026"
- "English Training Program"
- "Graduation Ceremony"

Each project owns:
- Template (certificate background image)
- Field layout (positions of dynamic text/image elements)
- Recipient data (students / participants)
- Data column to field mapping
- Fonts
- Signatures and stamps
- QR / verification configuration
- Security configuration (Project Key, Institution Key reference)
- Export configuration (filename patterns, output formats)

Generated certificates are **outputs**, not project resources.
A project export (.cstudio / .certproject) does NOT include generated certificate files.

### 3.2 Certificate Field (Box)

A Box is a positioned, styled region on the certificate canvas.

Properties:
- class_name (internal identifier / mapping key)
- source (data column it maps to)
- x, y, width, height (position and size)
- alignment, vertical_alignment
- font, font_size, font_weight, italic, underline
- letter_spacing, line_height
- text_color
- text_direction (LTR / RTL / auto)
- max_lines, overflow (clip / shrink / wrap)
- rotation, opacity
- visible, locked

### 3.3 Data Import

Recipient data comes from:
- Excel files (.xlsx)
- Pasted spreadsheet tables (clipboard)

The import normalizes data into a columnar internal model.
Column headers are mapped to field class names through the **Mapping** step.

### 3.4 Data Mapping

Excel columns are not fixed. A mapping connects:

"Student Name" (Excel column) => student_name (field class)
"اسم الطالب"  (Excel column) => student_name (field class)

This makes the system institution-agnostic.

### 3.5 Security Architecture

Three-level key hierarchy:

Institution Key (Master)
    down
Project Key (Derived / Independent)
    down
Certificate Signature

**Important distinction:**
- **Encryption** = protecting data confidentiality
- **Hash** = detecting content changes (integrity)
- **Digital Signature** = proving the issuer identity (authenticity)

The three are **separate** operations. Encryption alone does NOT prove authenticity.

Certificate verification record:
{
  "institution_id": "...",
  "project_id": "...",
  "certificate_id": "...",
  "student_class": "A001",
  "course": "Flutter",
  "issue_date": "2026-09-12",
  "document_hash": "...",
  "signature": "..."
}

### 3.6 QR Code

The QR code encodes verification metadata automatically.
Users do NOT manually construct QR payloads.
The system builds the QR content from the certificate's verification record.

### 3.7 Project Package Format

Extension: .cstudio or .certproject

Internal structure (a ZIP with custom extension):

project/
|-- manifest.json
|-- database.json
|-- template.png
|-- fonts/
|   |-- Cairo.ttf
|-- signatures/
|   |-- director.png
|-- configuration/
|   |-- fields.json
|   |-- export.json
|   |-- verification.json
|-- keys/
    |-- project.key

Generated certificate images/PDFs are intentionally excluded.

---

## 4. Application Architecture

### 4.1 Flutter Application Structure

lib/
|-- config/
|   |-- di/           # Dependency injection (injectable)
|   |-- env/          # Environment configuration
|   |-- localization/ # i18n (AR + EN)
|
|-- core/
|   |-- database/     # SQLCipher abstraction
|   |-- entities/     # Shared base entities
|   |-- error/        # Exceptions and Failures
|   |-- files/        # File picker, file system, sharing
|   |-- image/        # Image processing
|   |-- logging/      # App logger
|   |-- platform/     # Platform capability abstractions
|   |-- security/     # keys/, hashing/, signing/, encryption/
|   |-- services/     # Clipboard, PDF, QR
|   |-- utils/        # Constants, extensions, helpers
|   |-- validators/   # Certificate, file, project validators
|
|-- features/         # Each feature: data/ + domain/ + presentation/
|   |-- app/
|   |-- institution/
|   |-- projects/
|   |-- templates/
|   |-- certificate_designer/
|   |-- fonts/
|   |-- data_import/
|   |-- field_mapping/
|   |-- signatures/
|   |-- certificate_generation/
|   |-- certificates/
|   |-- export/
|   |-- project_package/
|   |-- verification/
|   |-- students/
|   |-- sharing/
|   |-- settings/
|
|-- routes/           # App router + route names
|-- shared/           # Extensions, themes, common widgets

### 4.2 Feature Layer Structure

Every feature follows Clean Architecture:

features/<feature_name>/
|-- data/
|   |-- datasources/    # Local data sources (SQLCipher)
|   |-- models/         # Data Transfer Objects (JSON serializable)
|   |-- repositories/   # Repository implementations
|-- domain/
|   |-- entities/       # Pure domain models (no JSON, no DB)
|   |-- repositories/   # Abstract repository interfaces
|   |-- usecases/       # Single-responsibility use cases
|-- presentation/
    |-- bloc/           # BLoC/Cubit + Events + States
    |-- screens/        # Full screen widgets
    |-- widgets/        # Reusable UI components

### 4.3 Internal Packages

packages/
|-- certificate_core/       # Shared domain primitives
|-- certificate_crypto/     # Keys, hashing, signing, encryption
|-- certificate_renderer/   # PDF and high-resolution image rendering
|-- certificate_excel/      # Excel + clipboard parsing
|-- certificate_verifier/   # Certificate verification logic
|-- certificate_project/    # Project package creation/import/export

### 4.4 Python Reference Package

python/
|-- certificate_crypto/
    |-- src/
    |-- tests/
    |-- pyproject.toml
    |-- README.md

The Flutter app does NOT depend on a Python runtime at user devices.
Python is the **canonical reference implementation** for cryptographic protocols.
Both Python and Dart implementations must produce compatible results.

---

## 5. Database Schema (SQLCipher)

Tables:
- institutions
- projects
- templates
- fonts
- signatures
- students
- certificate_fields
- certificate_layouts
- certificates
- verification_records
- settings

Key design:
- SQLCipher stores metadata and relationships
- Large files (templates, fonts, signatures, certificates) live on the filesystem
- File paths are stored in the DB, not file contents

Web platform uses IndexedDB or SQLCipher WASM (behind the LocalDatabase abstraction).

---

## 6. Technology Stack

| Layer | Technology |
|---|---|
| Application | Flutter / Dart |
| Architecture | Modular Clean Architecture |
| State Management | BLoC / Cubit |
| DI | injectable + get_it |
| Local DB | SQLCipher |
| Rendering | certificate_renderer (custom) |
| Cryptography | certificate_crypto (Dart + Python reference) |
| Excel Parsing | certificate_excel |
| Project Packaging | certificate_project |
| Verification | certificate_verifier |
| Localization | Flutter ARB (AR + EN) |

---

## 7. UX Flow and User Journey

### 7.1 Main User Journey

First Launch
    down
Institution Setup Wizard
    down
Home Screen (Projects)
    down
New Project Wizard
  Step 1: Project Information
  Step 2: Certificate Template
  Step 3: Data Source (Excel)
    down
Project Workspace
  |-- Overview / Dashboard
  |-- Data (Manage students)
  |-- Design (Certificate Designer)
  |-- Preview (per-student preview)
  |-- Generate (batch generation)
  |-- Certificates (library)
  |-- Export
    down
Verify Certificate (independent feature)

### 7.2 Certificate Designer UX

The Designer is the most important screen.
Layout:
- Left panel: Elements (Data Field, Text, Image, Signature, QR Code) + Layers
- Center: Certificate Canvas with zoom/grid/rulers/snap
- Right panel: Contextual Properties (changes based on selected element)

**Key UX rule:** Users never type {student_name} manually.
They click "Add Data Field" => select column from list => box appears automatically.

### 7.3 Platform Responsive Layout

- **Desktop:** Sidebar + Canvas + Properties Panel (3-column)
- **Tablet:** Collapsible sidebar + Canvas + Properties Drawer
- **Mobile:** Canvas + Bottom Navigation + Bottom Sheets for properties

### 7.4 Navigation Structure

Global navigation:
Home
Projects
Templates
Fonts
Signatures
Certificates
Verification
Settings

Inside a project (Workspace navigation):
Project
|-- Overview
|-- Data
|-- Design
|-- Preview
|-- Generate
|-- Certificates
|-- Export

---

## 8. Key UX Design Rules

1. **Never expose internal placeholder syntax** to users (no {student_name})
2. **Never show cryptographic details** to regular users (Ed25519, SHA-512, etc.)
3. **Contextual Properties Panel** — show only what is relevant to the selected element
4. **Wizard only for creation** — after creation, project workspace allows free navigation
5. **Autosave always** — do not rely on Ctrl+S only; show save state indicator
6. **Every screen needs:** Loading state, Empty state, Error state, Success state
7. **Progress over blocking** — long operations (generation) must show live progress
8. **Partial success is valid** — one failed certificate should not block the 39 that succeeded
9. **Offline-first indicator** — show offline status subtly, do not block functionality
10. **Drag and Drop support** on Desktop for: Excel files, template images, fonts, project files
11. **Undo/Redo is mandatory** in the Certificate Designer
12. **Keyboard shortcuts** are mandatory for Desktop (Ctrl+S, Ctrl+Z, Ctrl+G, etc.)

---

## 9. Code Conventions

### 9.1 Naming

| Type | Convention | Example |
|---|---|---|
| Files | snake_case | certificate_field.dart |
| Classes | PascalCase | CertificateField |
| Variables | camelCase | fieldPosition |
| Constants | kCamelCase | kDefaultFontSize |
| BLoC Events | PascalCase + Event suffix | AddCertificateFieldEvent |
| BLoC States | PascalCase + State suffix | CertificateDesignerLoadedState |

### 9.2 Use Case Rule

Each use case = one file = one public class with a single call() method.

class AddCertificateField {
  final CertificateDesignerRepository _repository;
  AddCertificateField(this._repository);

  Future<Either<Failure, CertificateField>> call(AddCertificateFieldParams params) {
    return _repository.addField(params);
  }
}

### 9.3 Repository Pattern

- domain/repositories/ = abstract interfaces
- data/repositories/ = concrete implementations
- Domain layer NEVER imports from data layer

### 9.4 Entity vs Model

- **Entity** (domain/entities/) = pure Dart class, no JSON, no DB
- **Model** (data/models/) = JSON-serializable DTO, includes fromJson / toJson

### 9.5 Error Handling

Use Either<Failure, T> for all repository and use case calls.
Never throw exceptions across layer boundaries.
Failures must map to human-readable messages at the presentation layer.

### 9.6 BLoC Pattern

States must cover: Initial, Loading, Loaded, Error, (Success for side effects).

### 9.7 Platform Services

Platform-specific code lives behind abstract interfaces.
The domain layer never knows which platform it is running on.

---

## 10. Security Implementation Rules

1. **Keys are never stored in plaintext** in project files or database
2. **Institution Key** is separate from all Project Keys
3. **Hash** and **Digital Signature** are distinct operations, always
4. **The Flutter app must work fully offline** — no dependency on Python runtime
5. **Python package** is for reference, protocol definition, and test vectors only
6. **QR payload** is always generated automatically — never manually constructed
7. **Verification** can run fully offline if public key material is available locally

---

## 11. Certificate Lifecycle

Draft
  down
Configured (template + data + mapping + design)
  down
Validated (pre-generation check passes)
  down
Generated (PDF + PNG created)
  down
Signed (hash computed, digital signature applied)
  down
Stored (certificate library)
  down
Exported / Shared
  down
Verified

---

## 12. Offline-First Requirements

These operations MUST work without internet:

Institution setup         yes
Project creation          yes
Template management       yes
Font management           yes
Excel import              yes
Data mapping              yes
Certificate design        yes
Certificate generation    yes
Cryptographic signing     yes
Local verification        yes
Project export / import   yes
Certificate library       yes
File sharing (system)     yes

Internet is ONLY needed for:
WhatsApp sharing (opens app)
Online verification portal (future)
Cloud backup (future)
Software updates

---

## 13. How the AI Should Reason About Tasks

When asked to implement a feature:

1. **Identify the feature** in features/ — which domain does it belong to?
2. **Start from domain** — define entity and use case before touching UI
3. **Check the data layer** — what does the local datasource need?
4. **Wire the BLoC** — what events and states are needed?
5. **Build the screen** — follow the UX rules in section 8
6. **Check responsiveness** — Desktop / Tablet / Mobile
7. **Handle all states** — Loading, Empty, Error, Success
8. **Respect offline-first** — no network calls in core domain logic
9. **Write actionable errors** — no raw exceptions in the UI

When asked about security:
- Always separate Hash, Digital Signature, and Encryption
- Never expose key material in UI
- Always use the established three-level key hierarchy

When asked about the Designer:
- Fields are Boxes with the full properties defined in section 3.2
- Users pick columns from a list, never type placeholders
- Undo/Redo is mandatory
- Contextual property panel changes based on selected element type

---

## 14. Key Files to Reference

| Purpose | File |
|---|---|
| Requirements | .agent/srs.md |
| Code structure | .agent/structure.md |
| UX design | .agent/uiux.md |
| Full project readme | README.md |
| Flutter dependencies | pubspec.yaml |

---

## 15. Development Philosophy

> A certificate should be treated as a **structured, reproducible, and
> verifiable digital artifact**, not simply as an image generated from a template.

Certificate
=
Visual Representation
+ Structured Data
+ Issuer Identity
+ Integrity (Hash)
+ Verification Information (Signature + QR)

---

*Certificate Studio — Design once. Generate many. Verify with confidence.*
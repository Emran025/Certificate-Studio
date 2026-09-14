import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:zxing2/qrcode.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_tables.dart';
import '../../../core/security/keys/institution_key_manager.dart';

enum CertificateVerificationStatus {
  valid,
  integrityCompromised,
  invalidSignature,
  unknownCertificate,
  unsupported,
  verificationDataMissing,
  failed,
}

class CertificateVerificationResult {
  const CertificateVerificationResult({
    required this.status,
    this.certificateId,
    this.recipient,
    this.studentClass,
    this.institution,
    this.course,
    this.issueDate,
    this.hash,
    this.algorithm,
    this.protocolVersion,
    this.reason,
    this.qrExtracted = false,
  });
  final CertificateVerificationStatus status;
  final String? certificateId;
  final String? recipient;
  final String? studentClass;
  final String? institution;
  final String? course;
  final String? issueDate;
  final String? hash;
  final String? algorithm;
  final String? protocolVersion;
  final String? reason;
  final bool qrExtracted;
  bool get isValid => status == CertificateVerificationStatus.valid;
}

class _ExtractedCertificate {
  const _ExtractedCertificate(this.record, this.artifactBytes);
  final Map<String, dynamic> record;
  final List<int> artifactBytes;
}

class CertificateVerificationService {
  CertificateVerificationService(this.database, this.keyStorage);
  final AppDatabase database;
  final KeyStorage keyStorage;
  static const _verificationMetadataKeys = {
    'format',
    'institution_id',
    'project_id',
    'certificate_id',
    'student_id',
    'public_key',
    'document_hash',
    'document_data',
    'signature',
  };

  Future<CertificateVerificationResult> verify(String certificateId) async {
    try {
      final records = await database.query(
        DatabaseTables.verificationRecords,
        where: {'certificate_id': certificateId},
        columns: ['payload_json'],
      );
      if (records.isEmpty) {
        return _result(
          CertificateVerificationStatus.unknownCertificate,
          certificateId: certificateId,
          reason: 'Certificate was not found in this offline workspace.',
        );
      }
      final record = _decode(records.first['payload_json']);
      final certificates = await database.query(
        DatabaseTables.certificates,
        where: {'id': certificateId},
        columns: ['document_json'],
      );
      final document = certificates.isEmpty
          ? <int>[]
          : utf8.encode((certificates.first['document_json'] as String?) ?? '');
      var publicKey = _embeddedPublicKey(record);
      if (publicKey == null) {
        final stored = await keyStorage.read(
          'project.${record['project_id']}.key',
        );
        if (stored == null) {
          return _fromRecord(
            record,
            CertificateVerificationStatus.verificationDataMissing,
            'The certificate public key is unavailable on this device.',
          );
        }
        publicKey = (await CertificateKeyPair.fromSeed(_hexDecode(stored)))
            .publicKey;
      }
      return await _verifyRecord(record, document, publicKey);
    } catch (error) {
      return _result(
        CertificateVerificationStatus.failed,
        certificateId: certificateId,
        reason: 'Verification could not be completed: $error',
      );
    }
  }

  Future<CertificateVerificationResult> verifyFile(
    List<int> bytes, {
    String? fileName,
  }) async {
    try {
      final extension = (fileName?.split('.').last ?? '').toLowerCase();
      if (const {'png', 'jpg', 'jpeg'}.contains(extension)) {
        final qrRecord = await _extractQrRecord(bytes);
        if (qrRecord == null) {
          // Generated images also carry the signed record after the image
          // stream. Prefer it when a QR reader cannot decode a heavily
          // compressed, resized, or screen-captured image.
          final embedded = _extractRecord(bytes);
          if (embedded != null) {
            return await _verifyEmbedded(embedded, extension: extension);
          }
          return _result(
            CertificateVerificationStatus.verificationDataMissing,
            reason: 'QR extraction failed and no embedded verification record was found in the image.',
          );
        }
        final hydratedQrRecord = await _hydrateQrRecord(qrRecord);
        final qrKey = _embeddedPublicKey(hydratedQrRecord);
        if (qrKey == null) {
          final embedded = _extractRecord(bytes);
          if (embedded != null) {
            final embeddedResult = await _verifyEmbedded(
              embedded,
              extension: extension,
            );
            if (embeddedResult.isValid) return embeddedResult;
          }
          return _fromRecord(
            hydratedQrRecord,
            CertificateVerificationStatus.verificationDataMissing,
            'QR extraction succeeded, but the QR payload has no public key.',
          );
        }
        final result = await _verifyRecord(
          hydratedQrRecord,
          _documentFromRecord(hydratedQrRecord),
          qrKey,
        );
        // QR decoding can return a valid-looking payload from a resized or
        // recompressed image. The PNG's embedded record is authoritative for
        // generated images, so retry it before reporting a false failure.
        if (!result.isValid) {
          final embedded = _extractRecord(bytes);
          if (embedded != null) {
            final embeddedResult = await _verifyEmbedded(
              embedded,
              extension: extension,
            );
            if (embeddedResult.isValid) return embeddedResult;
          }
        }
        return _copyWithQrExtracted(result);
      }
      final extracted = _extractRecord(bytes);
      if (extracted == null) {
        final qrRecord = await _extractQrFromPdf(bytes);
        if (qrRecord != null) {
          final result = await _verifyRecord(
            qrRecord,
            _documentFromRecord(qrRecord),
            _embeddedPublicKey(qrRecord)!,
          );
          return _copyWithQrExtracted(result);
        }
        return const CertificateVerificationResult(
          status: CertificateVerificationStatus.verificationDataMissing,
          reason:
              'This certificate does not contain embedded verification data.',
        );
      }
      return await _verifyEmbedded(extracted, extension: extension);
    } on FormatException catch (error) {
      return _result(
        CertificateVerificationStatus.unsupported,
        reason:
            'Unsupported or malformed certificate${fileName == null ? '' : ' ($fileName)'}: $error',
      );
    } catch (error) {
      return _result(
        CertificateVerificationStatus.failed,
        reason: 'Verification failed: $error',
      );
    }
  }

  Future<CertificateVerificationResult> _verifyEmbedded(
    _ExtractedCertificate extracted,
    {required String extension}
  ) async {
    final record = extracted.record;
    final publicKey = _embeddedPublicKey(record);
    if (publicKey == null) {
      return _fromRecord(
        record,
        CertificateVerificationStatus.verificationDataMissing,
        'The certificate public-key data is missing or unsupported.',
      );
    }
    final hashes = record['artifact_hashes'];
    final expectedArtifactHash = hashes is Map
        ? hashes[extension]
        : record['artifact_hash'];
    if (expectedArtifactHash is String &&
        expectedArtifactHash.isNotEmpty &&
        expectedArtifactHash != await sha256Base64Url(extracted.artifactBytes)) {
      return _fromRecord(
        record,
        CertificateVerificationStatus.integrityCompromised,
        'The PDF or image bytes were modified after issuance.',
      );
    }
    return await _verifyRecord(record, _documentFromRecord(record), publicKey);
  }

  Future<CertificateVerificationResult> verifyQr(String payload) async {
    try {
      final record = await _hydrateQrRecord(
        decodeVerificationQrPayload(payload.trim()),
      );
      var publicKey = _embeddedPublicKey(record);
      if (publicKey == null && record['project_id'] is String) {
        final stored = await keyStorage.read('project.${record['project_id']}.key');
        if (stored != null) {
          publicKey = (await CertificateKeyPair.fromSeed(_hexDecode(stored))).publicKey;
        }
      }
      if (publicKey == null) {
        return _fromRecord(
          record,
          CertificateVerificationStatus.verificationDataMissing,
          'The QR payload does not contain a public key.',
        );
      }
      return await _verifyRecord(
        record,
        _documentFromRecord(record),
        publicKey,
      );
    } catch (_) {
      return const CertificateVerificationResult(
        status: CertificateVerificationStatus.unsupported,
        reason: 'The QR payload is malformed or uses an unsupported protocol.',
      );
    }
  }

  Future<CertificateVerificationResult> _verifyRecord(
    Map<String, dynamic> record,
    List<int> document,
    SimplePublicKey publicKey,
  ) async {
    if (record['document_hash'] != await sha256Base64Url(document)) {
      return _fromRecord(
        record,
        CertificateVerificationStatus.integrityCompromised,
        'The certificate data was modified or does not match its embedded hash.',
      );
    }
    final valid = await verifyVerificationRecord(record, document, publicKey);
    return _fromRecord(
      record,
      valid
          ? CertificateVerificationStatus.valid
          : CertificateVerificationStatus.invalidSignature,
      valid ? null : 'The digital signature is invalid.',
    );
  }

  List<int> _documentFromRecord(Map<String, dynamic> record) {
    final embedded = record['document_data'];
    if (embedded is String) {
      return base64UrlDecode(embedded);
    }
    // Legacy v1 records did not include document_data. Keep this fallback for
    // old certificates only; all newly issued certificates use the exact
    // canonical bytes above and are independent of field names.
    final fields = record['fields'];
    if (fields is Map) {
      return canonicalJsonBytes({
        'project_id': record['project_id'],
        'student_id': record['student_id'],
        'fields': Map<String, dynamic>.from(fields),
      });
    }
    final dynamicFields = <String, dynamic>{
      for (final entry in record.entries)
        if (!_verificationMetadataKeys.contains(entry.key)) entry.key: entry.value,
    };
    return canonicalJsonBytes({
      'project_id': record['project_id'],
      'student_id': record['student_id'],
      'fields': dynamicFields,
    });
  }

  CertificateVerificationResult _fromRecord(
    Map<String, dynamic> record,
    CertificateVerificationStatus status,
    String? reason,
  ) {
    final fields = record['fields'] is Map
        ? Map<String, dynamic>.from(record['fields'] as Map)
        : record;
    final displayValues = fields.values
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .toList();
    return _result(
      status,
      certificateId: record['certificate_id']?.toString(),
      recipient:
          fields['recipient']?.toString() ??
          fields['name']?.toString() ??
          (displayValues.isEmpty ? null : displayValues.first),
      studentClass: fields['student_class']?.toString(),
      institution: record['institution_id']?.toString(),
      course: fields['course_name']?.toString() ??
          fields['course']?.toString() ??
          (displayValues.length > 1 ? displayValues[1] : null),
      issueDate: fields['issue_date']?.toString(),
      hash: record['document_hash']?.toString(),
      algorithm: 'Ed25519',
      protocolVersion: record['format']?.toString(),
      reason: reason,
    );
  }

  CertificateVerificationResult _result(
    CertificateVerificationStatus status, {
    String? certificateId,
    String? recipient,
    String? studentClass,
    String? institution,
    String? course,
    String? issueDate,
    String? hash,
    String? algorithm,
    String? protocolVersion,
    String? reason,
  }) => CertificateVerificationResult(
    status: status,
    certificateId: certificateId,
    recipient: recipient,
    studentClass: studentClass,
    institution: institution,
    course: course,
    issueDate: issueDate,
    hash: hash,
    algorithm: algorithm,
    protocolVersion: protocolVersion,
    reason: reason,
  );

  CertificateVerificationResult _copyWithQrExtracted(
    CertificateVerificationResult result,
  ) => CertificateVerificationResult(
    status: result.status,
    certificateId: result.certificateId,
    recipient: result.recipient,
    studentClass: result.studentClass,
    institution: result.institution,
    course: result.course,
    issueDate: result.issueDate,
    hash: result.hash,
    algorithm: result.algorithm,
    protocolVersion: result.protocolVersion,
    reason: result.reason,
    qrExtracted: true,
  );

  _ExtractedCertificate? _extractRecord(List<int> bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    const marker = 'CSTUDIO_RECORD_V1:';
    final markerIndex = text.lastIndexOf(marker);
    if (markerIndex < 0) return null;
    final match = RegExp(r'CSTUDIO_RECORD_V1:([A-Za-z0-9_-]+)')
        .firstMatch(text.substring(markerIndex));
    if (match == null) return null;
    final value = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(match.group(1)!))),
    );
    if (value is! Map) {
      throw const FormatException('embedded record is not an object');
    }
    return _ExtractedCertificate(
      Map<String, dynamic>.from(value),
      bytes.sublist(0, markerIndex),
    );
  }

  Future<Map<String, dynamic>?> _extractQrRecord(List<int> bytes) =>
      Isolate.run(() => _decodeQrRecord(bytes));

  Future<Map<String, dynamic>?> _extractQrFromPdf(List<int> bytes) async {
    try {
      await for (final page in Printing.raster(Uint8List.fromList(bytes), dpi: 300)) {
        final png = await page.toPng();
        final record = await _extractQrRecord(png);
        if (record != null) return record;
      }
    } catch (_) {
      // The embedded record path remains the authoritative PDF fallback.
    }
    return null;
  }

  static Map<String, dynamic>? _decodeQrRecord(List<int> bytes) {
    try {
      final decoded = img.decodeImage(Uint8List.fromList(bytes));
      if (decoded == null) return null;
      final reader = QRCodeReader();
      final hints = DecodeHints()
        ..put(DecodeHintType.tryHarder)
        ..put(DecodeHintType.possibleFormats, [BarcodeFormat.qrCode]);
      final grayscale = img.grayscale(decoded);
      final variants = <img.Image>[
        decoded,
        grayscale,
        img.adjustColor(grayscale, contrast: 1.35),
        img.invert(grayscale),
        img.copyResize(grayscale, width: decoded.width * 2),
        img.copyRotate(grayscale, angle: 90),
        img.copyRotate(grayscale, angle: 180),
        img.copyRotate(grayscale, angle: 270),
      ];
      // A certificate QR is often small relative to the page. Decode
      // overlapping tiles as well as the full page so text and background
      // detail cannot prevent the detector from finding its finder patterns.
      final tileWidth = (decoded.width * .55).round().clamp(96, decoded.width).toInt();
      final tileHeight = (decoded.height * .55).round().clamp(96, decoded.height).toInt();
      final xStep = ((decoded.width - tileWidth) / 2).round().clamp(1, decoded.width).toInt();
      final yStep = ((decoded.height - tileHeight) / 2).round().clamp(1, decoded.height).toInt();
      for (var y = 0; y < decoded.height; y += yStep) {
        for (var x = 0; x < decoded.width; x += xStep) {
          final left = x.clamp(0, decoded.width - tileWidth).toInt();
          final top = y.clamp(0, decoded.height - tileHeight).toInt();
          variants.add(img.copyCrop(
            grayscale,
            x: left,
            y: top,
            width: tileWidth,
            height: tileHeight,
          ));
          if (x + tileWidth >= decoded.width && y + tileHeight >= decoded.height) {
            break;
          }
        }
        if (y + tileHeight >= decoded.height) break;
      }
      for (final variant in variants) {
        // zxing2's RGBLuminanceSource expects ARGB values from an RGBA byte
        // stream. Passing BGRA here reverses the color channels and makes the
        // detector unreliable even for QR codes generated by this app.
        final rgba = variant.convert(numChannels: 4).getBytes(order: img.ChannelOrder.rgba);
        final source = RGBLuminanceSource(
          variant.width,
          variant.height,
          rgba.buffer.asInt32List(),
        );
        for (final binarizer in [
          GlobalHistogramBinarizer(source),
          HybridBinarizer(source),
        ]) {
          try {
            final result = reader.decode(BinaryBitmap(binarizer), hints: hints);
            return decodeVerificationQrPayload(result.text);
          } catch (_) {
            // Continue through the remaining image preprocessing variants.
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  SimplePublicKey? _embeddedPublicKey(Map<String, dynamic> record) {
    final value = record['public_key'];
    return value is Map
        ? publicKeyFromRecord(Map<String, dynamic>.from(value))
        : null;
  }

  Future<Map<String, dynamic>> _hydrateQrRecord(
    Map<String, dynamic> qrRecord,
  ) async {
    if (qrRecord['fields'] is Map && qrRecord['public_key'] is Map) {
      return qrRecord;
    }
    final certificateId = qrRecord['certificate_id']?.toString();
    if (certificateId == null || certificateId.isEmpty) return qrRecord;
    final rows = await database.query(
      DatabaseTables.verificationRecords,
      where: {'certificate_id': certificateId},
      columns: ['payload_json'],
    );
    if (rows.isEmpty) return qrRecord;
    final full = _decode(rows.first['payload_json']);
    if (full['document_hash'] != qrRecord['document_hash'] ||
        full['signature'] != qrRecord['signature']) {
      throw const FormatException('QR payload does not match the local certificate record');
    }
    final qrValues = qrRecord['_qr_first_values'];
    final fullFields = full['fields'];
    if (qrValues is List && fullFields is Map) {
      final expected = fullFields.values.take(2).map((value) => '$value').toList();
      if (qrValues.length != expected.length ||
          !List.generate(expected.length, (index) => qrValues[index] == expected[index])
              .every((matches) => matches)) {
        throw const FormatException('QR field values do not match the certificate record');
      }
    }
    return full;
  }

  Map<String, dynamic> _decode(Object? raw) =>
      raw is String ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : {};
  List<int> _hexDecode(String value) => [
    for (var i = 0; i < value.length; i += 2)
      int.parse(value.substring(i, i + 2), radix: 16),
  ];
}

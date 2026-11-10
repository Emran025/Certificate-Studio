import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/entities/operation_result.dart';
import '../../domain/entities/share_failure.dart';
import '../../domain/entities/share_target.dart';
import '../../domain/repositories/certificate_sharing_repository.dart';
import '../../domain/usecases/normalize_phone_number.dart';
import '../datasources/certificate_share_data_source.dart';

class CertificateSharingRepositoryImpl implements CertificateSharingRepository {
  CertificateSharingRepositoryImpl({
    required CertificateArtifactStore artifactStore,
    required CertificateShareDataSource dataSource,
    NormalizePhoneNumber normalizePhoneNumber = const NormalizePhoneNumber(),
  }) : _artifactStore = artifactStore,
       _dataSource = dataSource,
       _normalizePhoneNumber = normalizePhoneNumber;

  final CertificateArtifactStore _artifactStore;
  final CertificateShareDataSource _dataSource;
  final NormalizePhoneNumber _normalizePhoneNumber;

  @override
  Future<OperationResult<bool>> sharePdf({
    required String pdfReference,
    required String fileName,
    required ShareTarget target,
    String? phoneNumber,
  }) async {
    try {
      final isDirectWhatsApp =
          target == ShareTarget.whatsApp ||
          target == ShareTarget.whatsAppBusiness;
      final recipient = isDirectWhatsApp
          ? _normalizePhoneNumber(phoneNumber)
          : null;
      if (isDirectWhatsApp && recipient == null) {
        return const OperationFailure<bool>(
          'A valid international phone number is required.',
        );
      }

      final bytes = await _artifactStore.read(pdfReference);
      if (bytes == null || bytes.isEmpty) {
        return const OperationFailure<bool>('This PDF is unavailable.');
      }

      final shared = await _dataSource.sharePdf(
        bytes: bytes,
        fileName: _pdfFileName(fileName),
        target: target,
        phoneNumber: recipient,
      );
      if (!shared) {
        return const OperationFailure<bool>('Sharing was cancelled.');
      }
      return const OperationSuccess<bool>(true);
    } on CertificateShareFailure catch (failure) {
      return OperationFailure<bool>(failure.message);
    } catch (_) {
      return const OperationFailure<bool>('The PDF could not be shared.');
    }
  }

  String _pdfFileName(String value) {
    final safe = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    if (safe.isEmpty) return 'certificate.pdf';
    return safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';
  }
}

import '../../../../core/entities/operation_result.dart';
import '../entities/share_target.dart';

abstract interface class CertificateSharingRepository {
  Future<OperationResult<bool>> sharePdf({
    required String pdfReference,
    required String fileName,
    required ShareTarget target,
    String? phoneNumber,
  });
}

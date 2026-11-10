import '../../../../core/entities/operation_result.dart';
import '../entities/share_target.dart';
import '../repositories/certificate_sharing_repository.dart';

class ShareCertificatePdf {
  const ShareCertificatePdf(this._repository);

  final CertificateSharingRepository _repository;

  Future<OperationResult<bool>> call({
    required String pdfReference,
    required String fileName,
    required ShareTarget target,
    String? phoneNumber,
  }) => _repository.sharePdf(
    pdfReference: pdfReference,
    fileName: fileName,
    target: target,
    phoneNumber: phoneNumber,
  );
}

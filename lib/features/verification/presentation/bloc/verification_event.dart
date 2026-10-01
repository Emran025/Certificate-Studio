import 'dart:typed_data';

sealed class VerificationEvent {
  const VerificationEvent();
}

final class VerifyCertificateFile extends VerificationEvent {
  const VerifyCertificateFile(this.bytes, this.fileName);

  final Uint8List bytes;
  final String fileName;
}

final class VerifyCertificateId extends VerificationEvent {
  const VerifyCertificateId(this.id);

  final String id;
}

final class VerifyQrPayload extends VerificationEvent {
  const VerifyQrPayload(this.payload);

  final String payload;
}

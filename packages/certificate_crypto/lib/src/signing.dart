import 'package:cryptography/cryptography.dart';
import 'encoding.dart';

Future<List<int>> signBytes(List<int> message, SimpleKeyPair keyPair) async => (await Ed25519().sign(message, keyPair: keyPair)).bytes;
Future<bool> verifyBytes(List<int> message, List<int> signature, SimplePublicKey publicKey) async {
  if (signature.length != 64) return false;
  return Ed25519().verify(message, signature: Signature(signature, publicKey: publicKey));
}
String signatureBase64Url(List<int> signature) => base64UrlEncodeNoPadding(signature);

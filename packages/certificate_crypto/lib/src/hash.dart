import 'package:cryptography/cryptography.dart';
import 'encoding.dart';

Future<List<int>> sha256(List<int> bytes) async => (await Sha256().hash(bytes)).bytes;
Future<String> sha256Base64Url(List<int> bytes) async => base64UrlEncodeNoPadding(await sha256(bytes));
Future<bool> verifyHash(List<int> bytes, List<int> expected) async {
  final actual = await sha256(bytes);
  if (actual.length != expected.length) return false;
  var result = 0;
  for (var i = 0; i < actual.length; i++) result |= actual[i] ^ expected[i];
  return result == 0;
}

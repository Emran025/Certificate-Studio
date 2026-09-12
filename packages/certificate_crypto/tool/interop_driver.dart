import 'dart:convert';
import 'dart:io';
import 'package:certificate_crypto/certificate_crypto.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) throw ArgumentError('usage: interop_driver.dart <create|verify> <path>');
  final mode = args[0];
  final file = File(args[1]);
  if (mode == 'create') {
    final pair = await CertificateKeyPair.fromSeed(List<int>.generate(32, (i) => i));
    final message = utf8.encode('cross-language certificate payload');
    final record = await createVerificationRecord({'institution_id': 'interop-inst', 'project_id': 'interop-project', 'certificate_id': 'CERT-001', 'course': 'Flutter'}, message, pair.privateKey);
    final output = {'public_key': pair.publicRecord()['public_key'], 'message': base64UrlEncodeNoPadding(message), 'signature': signatureBase64Url(await signBytes(message, pair.privateKey)), 'record': record};
    await file.writeAsString(jsonEncode(output));
  } else if (mode == 'verify') {
    final input = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final publicKey = publicKeyFromRecord({'format': keyFormat, 'algorithm': 'Ed25519', 'public_key': input['public_key']});
    final message = base64UrlDecode(input['message'] as String);
    if (!await verifyBytes(message, base64UrlDecode(input['signature'] as String), publicKey)) exitCode = 1;
    if (!await verifyVerificationRecord(input['record'] as Map<String, dynamic>, utf8.encode('cross-language certificate payload'), publicKey)) exitCode = 1;
  } else {
    throw ArgumentError('unknown mode');
  }
}

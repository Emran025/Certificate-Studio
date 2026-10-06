import 'dart:async';
import 'dart:isolate';

import 'certificate_artifact_renderer.dart';

class PdfRenderWorker {
  PdfRenderWorker._(this._sendPort);

  final SendPort _sendPort;
  int _nextId = 0;
  final Map<int, Completer<List<int>>> _pending = {};

  static Future<PdfRenderWorker> start({
    required Map<String, List<int>> fontBytesByFamily,
    required List<int>? templateBytes,
    required Map<String, Object?> template,
  }) async {
    final handshake = ReceivePort();
    final responsePort = ReceivePort();
    await Isolate.spawn(_pdfRenderWorkerEntry, <String, Object?>{
      'reply': handshake.sendPort,
      'responses': responsePort.sendPort,
      'fonts': fontBytesByFamily,
      'templateBytes': templateBytes,
      'template': template,
    });
    final sendPort = await handshake.first as SendPort;
    final worker = PdfRenderWorker._(sendPort);
    responsePort.listen(worker._handleResponse);
    return worker;
  }

  Future<List<int>> render(Map<String, Object?> args) {
    final id = _nextId++;
    final completer = Completer<List<int>>();
    _pending[id] = completer;
    _sendPort.send(<Object?>[id, args]);
    return completer.future;
  }

  void _handleResponse(dynamic message) {
    if (message is! List || message.length < 2) return;
    final completer = _pending.remove(message[0] as int);
    if (completer == null) return;
    final error = message[1];
    if (error is String) {
      completer.completeError(StateError(error));
    } else {
      completer.complete(List<int>.from(error as List));
    }
  }
}

void _pdfRenderWorkerEntry(Map<String, Object?> init) {
  final commands = ReceivePort();
  (init['reply'] as SendPort).send(commands.sendPort);
  final fonts = Map<String, List<int>>.from(
    (init['fonts'] as Map).map(
      (key, value) => MapEntry(key.toString(), List<int>.from(value as List)),
    ),
  );
  final prepared = CertificateArtifactRenderer.preparePdfBackground(
    init['templateBytes'] == null
        ? null
        : List<int>.from(init['templateBytes'] as List),
    Map<String, Object?>.from(init['template'] as Map),
  );
  final background = prepared?.bytes;
  final backgroundWidth = prepared?.width;
  final backgroundHeight = prepared?.height;
  commands.listen((message) async {
    if (message is! List || message.length < 2) return;
    final id = message[0];
    try {
      final args = Map<String, Object?>.from(message[1] as Map);
      final bytes = await CertificateArtifactRenderer.renderPdf(
        values: Map<String, dynamic>.from(args['values'] as Map),
        fields: [
          for (final field in args['fields'] as List)
            Map<String, Object?>.from(field as Map),
        ],
        hash: args['hash'] as String,
        record: Map<String, dynamic>.from(args['record'] as Map),
        templateBytes: null,
        template: Map<String, Object?>.from(args['template'] as Map),
        fontBytesByFamily: fonts,
        preparedBackgroundBytes: background,
        preparedImageWidth: backgroundWidth,
        preparedImageHeight: backgroundHeight,
      );
      (init['responses'] as SendPort).send(<Object?>[id, bytes]);
    } catch (error, stack) {
      (init['responses'] as SendPort).send(<Object?>[id, '$error\n$stack']);
    }
  });
}

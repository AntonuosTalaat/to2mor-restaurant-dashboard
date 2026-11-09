// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> readWebFileBytes(dynamic file) async {
  final completer = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.onError.listen((error) {
    if (!completer.isCompleted) {
      completer.completeError('File read error: ${error.toString()}');
    }
  });

  reader.onLoadEnd.listen((_) {
    if (completer.isCompleted) return;
    try {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else if (result is Uint8List) {
        completer.complete(result);
      } else if (result == null) {
        completer.completeError('File read returned null');
      } else {
        completer.completeError(
          'Unexpected file read result type: ${result.runtimeType}',
        );
      }
    } catch (e) {
      completer.completeError(e);
    }
  });

  reader.readAsArrayBuffer(file);

  return completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('File read timed out'),
  );
}

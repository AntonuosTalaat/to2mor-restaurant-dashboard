import 'dart:typed_data';

/// Stub: reading browser File objects is web-only.
Future<Uint8List> readWebFileBytes(dynamic file) {
  throw UnsupportedError('Web file reading is only available on web');
}

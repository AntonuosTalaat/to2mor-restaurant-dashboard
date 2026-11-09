// Stub for dart:io when building for web (dart:io is not available on web).
// Used only so that CloudinaryService compiles; the File branch is never taken on web.

import 'dart:typed_data';

class File {
  File(String path) : _path = path;
  final String _path;
  String get path => _path;
  Future<bool> exists() async => false;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
}

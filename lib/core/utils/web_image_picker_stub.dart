/// Stub: غير مستخدم على الموبايل
Future<WebPickResult?> pickImageOnWeb() async => null;
class WebPickResult {
  WebPickResult(this.bytes, this.extension);
  final List<int> bytes;
  final String extension;
}

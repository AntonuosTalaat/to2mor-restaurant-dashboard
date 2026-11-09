// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// نتيجة اختيار صورة على الويب
class WebPickResult {
  WebPickResult(this.bytes, this.extension);
  final List<int> bytes;
  final String extension;
}

Future<WebPickResult?> pickImageOnWeb() async {
  final completer = Completer<WebPickResult?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/gif,image/webp'
    ..style.display = 'none';

  void cleanup() {
    input.remove();
  }

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      cleanup();
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      try {
        final result = reader.result;
        if (result == null || result is! String) {
          if (!completer.isCompleted) completer.complete(null);
          cleanup();
          return;
        }
        // قراءة كـ Data URL ثم فك base64 (يعمل بشكل موثوق على كل المتصفحات)
        final dataUrl = result;
        final parts = dataUrl.split(',');
        final base64 = parts.length >= 2 ? parts[1] : null;
        if (base64 == null || base64.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
          cleanup();
          return;
        }
        final bytes = base64Decode(base64);
        final ext = _extensionFromMime(file.type) ?? 'jpg';
        if (!completer.isCompleted)
          completer.complete(WebPickResult(bytes, ext));
      } catch (_) {
        if (!completer.isCompleted) completer.complete(null);
      }
      cleanup();
    });
    reader.readAsDataUrl(file);
  });

  html.document.body?.append(input);
  input.click();
  return completer.future;
}

String? _extensionFromMime(String? mime) {
  if (mime == null) return null;
  if (mime.contains('png')) return 'png';
  if (mime.contains('gif')) return 'gif';
  if (mime.contains('webp')) return 'webp';
  return 'jpg';
}

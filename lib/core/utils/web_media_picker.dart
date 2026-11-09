// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// نتيجة اختيار ملف (صورة أو فيديو) على الويب
class WebPickResult {
  const WebPickResult({
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });

  final List<int> bytes;
  final String extension;
  final String mimeType;

  bool get isVideo => mimeType.startsWith('video/');
  bool get isImage => mimeType.startsWith('image/');
}

// ── Image picker ──────────────────────────────────────────────────────────────

Future<WebPickResult?> pickImageOnWeb() => _pick(
      accept: 'image/jpeg,image/png,image/gif,image/webp',
    );

// ── Video picker ──────────────────────────────────────────────────────────────

Future<WebPickResult?> pickVideoOnWeb() => _pick(
      accept: 'video/mp4,video/quicktime,video/x-msvideo,video/webm',
    );

// ── Combined picker (صور + فيديوهات) ─────────────────────────────────────────

Future<WebPickResult?> pickMediaOnWeb() => _pick(
      accept:
          'image/jpeg,image/png,image/gif,image/webp,'
          'video/mp4,video/quicktime,video/x-msvideo,video/webm',
    );

// ── Core implementation ───────────────────────────────────────────────────────

Future<WebPickResult?> _pick({required String accept}) async {
  final completer = Completer<WebPickResult?>();

  final input = html.FileUploadInputElement()
    ..accept = accept
    ..style.display = 'none';

  void complete(WebPickResult? result) {
    if (!completer.isCompleted) completer.complete(result);
    input.remove();
  }

  input.onChange.listen((_) {
    final file = input.files?.firstOrNull;
    if (file == null) {
      complete(null);
      return;
    }

    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      try {
        final result = reader.result;
        if (result is! String) {
          complete(null);
          return;
        }

        final parts = result.split(',');
        if (parts.length < 2 || parts[1].isEmpty) {
          complete(null);
          return;
        }

        final bytes = base64Decode(parts[1]);
        final ext = _extensionFromMime(file.type);
        if (ext == null) {
          complete(null);
          return;
        }

        complete(
          WebPickResult(
            bytes: bytes,
            extension: ext,
            mimeType: file.type,
          ),
        );
      } catch (_) {
        complete(null);
      }
    });

    reader.readAsDataUrl(file);
  });

  html.document.body?.append(input);
  input.click();

  return completer.future;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _extensionFromMime(String? mime) {
  return switch (mime) {
    'image/png' => 'png',
    'image/gif' => 'gif',
    'image/webp' => 'webp',
    'image/jpeg' || 'image/jpg' => 'jpg',
    'video/mp4' => 'mp4',
    'video/quicktime' => 'mov',
    'video/x-msvideo' => 'avi',
    'video/webm' => 'webm',
    _ => null,
  };
}
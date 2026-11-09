import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// On web, errors thrown inside a Future converted from a JS Promise are
/// wrapped in a Dart object that exposes the underlying boxed error via
/// the `.error` and `.stack` properties. We extract whatever we can find.
void unwrapBoxedError(Object error, StringBuffer buffer) {
  // First try dynamic dispatch — works for the Dart-side `_BoxedDartError`
  // wrapper that exposes `.error` and `.stack` as documented in the hint
  // message ("Use the properties 'error' to fetch the boxed error").
  try {
    final dynamic d = error;
    final inner = d.error as Object?;
    if (inner != null) {
      buffer.writeln('  boxed.error: $inner');
      _writeProp(buffer, inner, 'message', label: 'boxed.error.message');
      _writeProp(buffer, inner, 'code', label: 'boxed.error.code');
      _writeProp(buffer, inner, 'name', label: 'boxed.error.name');
    }
    final st = d.stack as Object?;
    if (st != null) {
      final lines = st.toString().split('\n').take(10).join('\n');
      buffer.writeln('  boxed.stack:');
      buffer.writeln(lines);
    }
    if (inner != null || st != null) return;
  } catch (_) {
    // Fall through to JS interop attempt.
  }

  // Fallback: read properties via JS interop in case the wrapper is a
  // plain JS object rather than a Dart wrapper.
  try {
    final jsObj = error as JSObject;
    final inner = jsObj.getProperty<JSAny?>('error'.toJS);
    if (inner != null) buffer.writeln('  js.error: $inner');
    final code = jsObj.getProperty<JSAny?>('code'.toJS);
    if (code != null) buffer.writeln('  js.code: $code');
    final message = jsObj.getProperty<JSAny?>('message'.toJS);
    if (message != null) buffer.writeln('  js.message: $message');
    final stack = jsObj.getProperty<JSAny?>('stack'.toJS);
    if (stack != null) {
      final lines = stack.toString().split('\n').take(10).join('\n');
      buffer.writeln('  js.stack:');
      buffer.writeln(lines);
    }
  } catch (_) {
    // Logging must never throw.
  }
}

void _writeProp(
  StringBuffer buffer,
  Object obj,
  String prop, {
  required String label,
}) {
  try {
    final dynamic d = obj;
    final value = switch (prop) {
      'message' => d.message,
      'code' => d.code,
      'name' => d.name,
      _ => null,
    } as Object?;
    if (value != null) buffer.writeln('  $label: $value');
  } catch (_) {}
}

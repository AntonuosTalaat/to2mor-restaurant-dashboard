import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_error_unwrap_stub.dart'
    if (dart.library.js_interop) 'firestore_error_unwrap_web.dart';

/// Prints Firestore failures to the terminal (e.g. composite index creation URL).
void logFirestoreQueryFailure(
  Object error, {
  required String operation,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
}) {
  final buffer = StringBuffer()
    ..writeln('')
    ..writeln('══════════════════════════════════════════════════════')
    ..writeln('Firestore query failed: $operation')
    ..writeln('══════════════════════════════════════════════════════');

  if (context != null && context.isNotEmpty) {
    for (final entry in context.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
  }

  if (error is FirebaseException) {
    buffer
      ..writeln('  code: ${error.code}')
      ..writeln('  plugin: ${error.plugin}')
      ..writeln('  message: ${error.message}');
  }

  buffer.writeln('  error.runtimeType: ${error.runtimeType}');
  buffer.writeln('  error.toString(): $error');

  // On web, errors crossing the JS↔Dart bridge get boxed; pry them open.
  unwrapBoxedError(error, buffer);

  final searchable = StringBuffer(error.toString())..writeln(buffer.toString());
  if (error is FirebaseException && error.message != null) {
    searchable.writeln(error.message);
  }

  final indexUrl = RegExp(
    r'https://console\.firebase\.google\.com[^\s\)\]\>]+',
  ).firstMatch(searchable.toString());

  if (indexUrl != null) {
    buffer
      ..writeln('──────────────────────────────────────────────────────')
      ..writeln('Create composite index (open in browser):')
      ..writeln(indexUrl.group(0)!)
      ..writeln('──────────────────────────────────────────────────────');
  }

  if (stackTrace != null) {
    buffer
      ..writeln('── dart stack trace (first 12 lines) ──')
      ..writeln(
        stackTrace
            .toString()
            .split('\n')
            .take(12)
            .join('\n'),
      );
  }

  buffer.writeln('══════════════════════════════════════════════════════');
  buffer.writeln('');

  // ignore: avoid_print
  print(buffer.toString());
}

import 'dart:math';

String generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();

  return List.generate(
    8,
    (index) => chars[random.nextInt(chars.length)],
  ).join();
}

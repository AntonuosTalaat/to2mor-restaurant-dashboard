import 'package:firebase_auth/firebase_auth.dart';

/// Waits until Firebase Auth has a user and ID token before Firestore calls.
/// Prevents `permission-denied` right after login (auth token not yet attached).
Future<void> ensureFirebaseAuthReady() async {
  final auth = FirebaseAuth.instance;
  var user = auth.currentUser;

  user ??= await auth
      .authStateChanges()
      .firstWhere((u) => u != null)
      .timeout(const Duration(seconds: 10));

  await user!.getIdToken();
}

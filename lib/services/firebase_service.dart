import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../firebase_options.dart';

/// Firebase authentication and initialization service.
///
/// Wraps Firebase Auth for Google Sign-In and Apple Sign-In.
class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Initialize Firebase. Call once at app startup.
  /// Skips entirely if firebase_options.dart still has PLACEHOLDER values.
  Future<void> initialize() async {
    if (_initialized) return;

    // Guard against PLACEHOLDER values — avoid native crash on iOS/macOS
    try {
      final opts = DefaultFirebaseOptions.currentPlatform;
      if (opts.projectId == 'PLACEHOLDER' || opts.apiKey == 'PLACEHOLDER') {
        debugPrint('⚠️ [Firebase] Not configured — run flutterfire configure');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [Firebase] No platform config: $e');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('🔥 [Firebase] Service initialized');
    } catch (e) {
      debugPrint('⚠️ [Firebase] Init failed (offline mode): $e');
    }
  }

  /// Current signed-in user, or null.
  User? get _currentUser => _initialized ? _auth.currentUser : null;

  /// Current signed-in user ID, or null if not signed in.
  String? get currentUserId => _currentUser?.uid;

  /// Current user display name.
  String? get currentUserName => _currentUser?.displayName;

  /// Current user email.
  String? get currentUserEmail => _currentUser?.email;

  /// Current user photo URL.
  String? get currentUserPhotoUrl => _currentUser?.photoURL;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _currentUser != null;

  /// Stream of auth state changes (user ID or null).
  Stream<String?> get authStateChanges => _initialized
      ? _auth.authStateChanges().map((user) => user?.uid)
      : const Stream.empty();

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    if (!_initialized) throw Exception('Firebase 尚未設定，請先執行 flutterfire configure');
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // User cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
    debugPrint('🔥 [Firebase] Google sign-in successful: ${_currentUser?.uid}');
  }

  /// Sign in with Apple.
  Future<void> signInWithApple() async {
    if (!_initialized) throw Exception('Firebase 尚未設定，請先執行 flutterfire configure');
    // Generate nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple only provides name on first sign-in; persist it to profile
    final displayName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((n) => n != null && n.isNotEmpty).join(' ');

    if (displayName.isNotEmpty &&
        (userCredential.user?.displayName == null ||
            userCredential.user!.displayName!.isEmpty)) {
      await userCredential.user?.updateDisplayName(displayName);
    }

    debugPrint('🔥 [Firebase] Apple sign-in successful: ${_currentUser?.uid}');
  }

  /// Sign out of the current account.
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    debugPrint('🔥 [Firebase] Signed out');
  }

  /// Generate a random nonce string for Apple Sign-In.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA-256 hash of a string, returned as hex.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

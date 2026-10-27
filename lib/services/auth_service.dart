import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Usa esclusivamente lo scope standard per evitare blocchi OAuth/Google Play Services su Android
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: DefaultFirebaseOptions.googleOAuthClientId,
  );

  String? _accessToken;
  String? get accessToken => _accessToken;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Effettua il login con Google e collega le credenziali a Firebase Auth
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Login annullato dall'utente
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      _accessToken = googleAuth.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Effettua l'accesso anonimo con Firebase Auth (fallback se Google Sign-In fallisce per SHA-1)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      return cred;
    } catch (e) {
      debugPrint('Anonymous Auth Error: $e');
      rethrow;
    }
  }

  /// Disconnette l'utente da Google e Firebase
  Future<void> signOut() async {
    _accessToken = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

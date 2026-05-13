import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_model.dart';
import '../services/firebase_service.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);

final appUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authControllerProvider);
  final user = auth.valueOrNull;
  if (!FirebaseService.isAvailable || user == null) {
    return Stream.value(null);
  }
  return FirebaseService.userDoc(user.uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  });
});

class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    if (!FirebaseService.isAvailable) return null;
    return FirebaseService.auth.authStateChanges().first;
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    });
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await FirebaseService.auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await credential.user?.updateDisplayName(name.trim());
      await _ensureUserDoc(credential.user, overrideName: name.trim());
      return credential.user;
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return state.valueOrNull;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseService.auth.signInWithCredential(
        credential,
      );
      await _ensureUserDoc(userCredential.user);
      return userCredential.user;
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final userCredential = await FirebaseService.auth.signInWithCredential(
        credential,
      );
      await _ensureUserDoc(userCredential.user);
      return userCredential.user;
    });
  }

  Future<void> resetPassword(String email) {
    return FirebaseService.auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateThemeMode(String themeMode) async {
    final user = state.valueOrNull;
    if (user == null) return;
    await FirebaseService.userDoc(
      user.uid,
    ).set({'themeMode': themeMode}, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    if (!FirebaseService.isAvailable) return;
    await FirebaseService.auth.signOut();
    await GoogleSignIn().signOut();
    state = const AsyncData(null);
  }

  Future<void> _ensureUserDoc(User? user, {String? overrideName}) async {
    if (user == null) return;
    final doc = FirebaseService.userDoc(user.uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;
    final appUser = AppUser(
      id: user.uid,
      name: overrideName?.isNotEmpty == true
          ? overrideName!
          : user.displayName ?? 'Sinh vien',
      email: user.email ?? '',
      avatarUrl: user.photoURL,
    );
    await doc.set(appUser.toMap());
  }
}

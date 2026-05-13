import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'firebase_service.dart' as app_firebase;

class FirebaseDiagnosticsResult {
  const FirebaseDiagnosticsResult({
    required this.initialized,
    required this.projectId,
    required this.appId,
    required this.platform,
    required this.authAvailable,
    required this.firestoreAvailable,
    required this.storageBucket,
    this.currentUserId,
    this.firestoreMessage,
    this.error,
  });

  final bool initialized;
  final String projectId;
  final String appId;
  final String platform;
  final bool authAvailable;
  final bool firestoreAvailable;
  final String storageBucket;
  final String? currentUserId;
  final String? firestoreMessage;
  final Object? error;

  List<String> toLogLines() {
    return [
      'Firebase initialized: $initialized',
      'Project ID: $projectId',
      'App ID: $appId',
      'Platform: $platform',
      'Auth available: $authAvailable',
      'Firestore available: $firestoreAvailable',
      'Storage bucket: $storageBucket',
      'Current user: ${currentUserId ?? "none"}',
      if (firestoreMessage != null) 'Firestore check: $firestoreMessage',
      if (error != null) 'Error: $error',
    ];
  }
}

class FirebaseDiagnosticsService {
  const FirebaseDiagnosticsService._();

  static Future<FirebaseDiagnosticsResult> checkFirebaseStatus() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      final initialized =
          Firebase.apps.isNotEmpty && app_firebase.FirebaseService.isAvailable;
      final user = initialized ? FirebaseAuth.instance.currentUser : null;
      var firestoreAvailable = initialized;
      String? firestoreMessage;

      if (initialized && user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'diagnosticsLastCheckedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          firestoreMessage = 'Đọc/ghi users/${user.uid} thành công.';
        } on Object catch (error) {
          firestoreAvailable = false;
          firestoreMessage =
              'Không ghi được Firestore. Nếu permission-denied, kiểm tra rules users/{userId}. Chi tiết: $error';
        }
      } else if (initialized) {
        firestoreMessage = 'Chưa đăng nhập nên bỏ qua test write Firestore.';
      }

      final result = FirebaseDiagnosticsResult(
        initialized: initialized,
        projectId: options.projectId,
        appId: options.appId,
        platform: _platformName(),
        authAvailable: initialized,
        firestoreAvailable: firestoreAvailable,
        storageBucket: options.storageBucket ?? '',
        currentUserId: user?.uid,
        firestoreMessage: firestoreMessage,
      );
      debugPrint(result.toLogLines().join('\n'));
      return result;
    } on Object catch (error) {
      final result = FirebaseDiagnosticsResult(
        initialized: Firebase.apps.isNotEmpty,
        projectId: 'unknown',
        appId: 'unknown',
        platform: _platformName(),
        authAvailable: false,
        firestoreAvailable: false,
        storageBucket: '',
        error: error,
      );
      debugPrint(result.toLogLines().join('\n'));
      return result;
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}

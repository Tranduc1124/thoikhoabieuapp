import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  static bool isAvailable = false;
  static Object? initializationError;

  static Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      isAvailable = true;
      initializationError = null;
      return true;
    } catch (error) {
      if (Firebase.apps.isNotEmpty) {
        isAvailable = true;
        initializationError = null;
        return true;
      }
      isAvailable = false;
      initializationError = error;
      return false;
    }
  }

  static FirebaseAuth get auth {
    _ensureAvailable();
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore get firestore {
    _ensureAvailable();
    return FirebaseFirestore.instance;
  }

  static FirebaseStorage get storage {
    _ensureAvailable();
    return FirebaseStorage.instance;
  }

  static DocumentReference<Map<String, dynamic>> userDoc(String userId) {
    return firestore.collection('users').doc(userId);
  }

  static CollectionReference<Map<String, dynamic>> schedules(String userId) {
    return userDoc(userId).collection('schedules');
  }

  static CollectionReference<Map<String, dynamic>> studyLogs(String userId) {
    return userDoc(userId).collection('studyLogs');
  }

  static DocumentReference<Map<String, dynamic>> appSettings(String userId) {
    return userDoc(userId).collection('settings').doc('app');
  }

  static DocumentReference<Map<String, dynamic>> notificationSettings(
    String userId,
  ) {
    return userDoc(userId).collection('settings').doc('notification');
  }

  static CollectionReference<Map<String, dynamic>> publicShares() {
    return firestore.collection('public_shares');
  }

  static void _ensureAvailable() {
    if (!isAvailable) {
      throw StateError(
        'Firebase chưa cấu hình hoặc khởi tạo thất bại. Kiểm tra '
        'lib/firebase_options.dart và GoogleService-Info.plist.',
      );
    }
  }
}

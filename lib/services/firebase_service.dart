import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  FirebaseService._();

  static bool isAvailable = false;
  static Object? initializationError;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      isAvailable = true;
      initializationError = null;
    } catch (error) {
      isAvailable = false;
      initializationError = error;
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

  static DocumentReference<Map<String, dynamic>> userDoc(String userId) {
    return firestore.collection('users').doc(userId);
  }

  static CollectionReference<Map<String, dynamic>> schedules(String userId) {
    return userDoc(userId).collection('schedules');
  }

  static CollectionReference<Map<String, dynamic>> studyLogs(String userId) {
    return userDoc(userId).collection('studyLogs');
  }

  static void _ensureAvailable() {
    if (!isAvailable) {
      throw StateError(
        'Firebase chua duoc cau hinh. Hay them Firebase options hoac '
        'GoogleService-Info.plist vao ios/Runner.',
      );
    }
  }
}

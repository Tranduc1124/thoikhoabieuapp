import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

class ProfileService {
  const ProfileService({required this.userId});

  final String userId;

  Future<void> updateProfile({
    required String name,
    String? avatarUrl,
    int? accentColor,
    String? themeMode,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    };
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (accentColor != null) data['accentColor'] = accentColor;
    if (themeMode != null) data['themeMode'] = themeMode;
    await FirebaseService.userDoc(userId).set(data, SetOptions(merge: true));
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name.trim());
    if (avatarUrl != null) {
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(avatarUrl);
    }
  }

  Future<String?> pickAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (picked == null) return null;
    try {
      final ref = FirebaseService.storage.ref('users/$userId/avatar.jpg');
      await ref.putFile(File(picked.path));
      return ref.getDownloadURL();
    } catch (_) {
      return picked.path;
    }
  }
}

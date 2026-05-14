import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/profile_card_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class ProfileService {
  const ProfileService({required this.userId});

  final String userId;

  Future<void> updateProfile({
    required String name,
    String? username,
    String? bio,
    String? avatarUrl,
    int? accentColor,
    String? themeMode,
    String? profileTheme,
    String? favoriteSubject,
    bool? isProfilePublic,
    bool? allowFriendsToViewTimetable,
    bool? hideStatistics,
    bool? hideStreak,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    };
    if (username != null) {
      data['username'] = username.trim();
    }
    if (bio != null) {
      data['bio'] = bio.trim();
    }
    if (avatarUrl != null) {
      data['avatarUrl'] = avatarUrl;
    }
    if (accentColor != null) {
      data['accentColor'] = accentColor;
    }
    if (themeMode != null) {
      data['themeMode'] = themeMode;
    }
    if (profileTheme != null) {
      data['profileTheme'] = profileTheme;
    }
    if (favoriteSubject != null) {
      data['favoriteSubject'] = favoriteSubject.trim();
    }
    if (isProfilePublic != null) {
      data['isProfilePublic'] = isProfilePublic;
    }
    if (allowFriendsToViewTimetable != null) {
      data['allowFriendsToViewTimetable'] = allowFriendsToViewTimetable;
    }
    if (hideStatistics != null) {
      data['hideStatistics'] = hideStatistics;
    }
    if (hideStreak != null) {
      data['hideStreak'] = hideStreak;
    }

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

  Future<ProfileCardModel> createProfileCard({
    required AppUser user,
    required List<ScheduleModel> schedules,
    required double weeklyHours,
  }) async {
    final cardId = const Uuid().v4();
    final profileLink = 'thoikhoabieu://profile/$cardId';
    final card = ProfileCardModel(
      id: cardId,
      ownerId: userId,
      displayName: user.name,
      username: user.username,
      bio: user.bio,
      favoriteSubject: user.favoriteSubject,
      studyStreak: user.studyStreak,
      weeklyHours: weeklyHours,
      totalClasses: schedules.length,
      avatarUrl: user.avatarUrl,
      theme: user.profileTheme,
      qrLink: profileLink,
    );
    await FirebaseService.profileCards().doc(cardId).set(card.toMap());
    return card;
  }
}

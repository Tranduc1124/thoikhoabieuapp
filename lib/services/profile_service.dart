import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../api/api.dart';
import '../models/profile_card_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';
import 'app_feedback_service.dart';

class AvatarUploadResult {
  const AvatarUploadResult({
    this.avatarUrl,
    this.warningMessage,
    this.didUpdate = false,
  });

  final String? avatarUrl;
  final String? warningMessage;
  final bool didUpdate;

  bool get didPickImage => avatarUrl != null || warningMessage != null;
}

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
    final data = <String, dynamic>{'name': name.trim()};
    if (username != null) data['username'] = username.trim();
    if (bio != null) data['bio'] = bio.trim();
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (accentColor != null) data['accentColor'] = accentColor;
    if (themeMode != null) data['themeMode'] = themeMode;
    if (profileTheme != null) data['profileTheme'] = profileTheme;
    if (favoriteSubject != null) {
      data['favoriteSubject'] = favoriteSubject.trim();
    }
    if (isProfilePublic != null) data['isProfilePublic'] = isProfilePublic;
    if (allowFriendsToViewTimetable != null) {
      data['allowFriendsToViewTimetable'] = allowFriendsToViewTimetable;
    }
    if (hideStatistics != null) data['hideStatistics'] = hideStatistics;
    if (hideStreak != null) data['hideStreak'] = hideStreak;

    try {
      await Api.call('profile.update', data: data);
    } catch (error) {
      throw AppUserMessageException(
        error.toString().replaceFirst('Exception: ', ''),
        debugMessage: 'updateProfile failed: $error',
      );
    }
  }

  Future<AvatarUploadResult> pickAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (picked == null) {
      return const AvatarUploadResult();
    }

    try {
      final data = await Api.upload(
        'profile.uploadAvatar',
        file: File(picked.path),
        fileField: 'avatar',
      );
      return AvatarUploadResult(
        avatarUrl: data['avatarUrl']?.toString(),
        didUpdate: true,
      );
    } catch (error) {
      final message = error.toString();
      if (message.contains('Chưa cấu hình lưu ảnh đại diện')) {
        return const AvatarUploadResult(
          warningMessage: 'Chưa cấu hình lưu ảnh đại diện.',
        );
      }
      throw AppUserMessageException(
        message.replaceFirst('Exception: ', ''),
        debugMessage: 'pickAndUploadAvatar failed: $error',
      );
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
    final data = await Api.call('profileCard.create', data: card.toMap());
    return ProfileCardModel.fromMap(
      Map<String, dynamic>.from((data['card'] as Map?) ?? card.toMap()),
    );
  }
}

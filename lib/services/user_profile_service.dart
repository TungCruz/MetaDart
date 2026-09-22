import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const maxAvatarBytes = 700 * 1024;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserProfile> loadProfile() async {
    final user = _requireUser();
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final data = snapshot.data() ?? <String, dynamic>{};
      return UserProfile(
        id: user.uid,
        name: (data['name'] as String?)?.trim().isNotEmpty == true
            ? (data['name'] as String).trim()
            : _fallbackName(user),
        email: (data['email'] as String?)?.trim().isNotEmpty == true
            ? (data['email'] as String).trim()
            : (user.email ?? ''),
        phone: data['phone'] as String? ?? '',
        age: (data['age'] as num?)?.toInt(),
      );
    } catch (error, stackTrace) {
      _log('loadProfile', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required int age,
    Uint8List? avatarBytes,
    String? avatarContentType,
  }) async {
    final user = _requireUser();
    if (avatarBytes != null && avatarBytes.length > maxAvatarBytes) {
      throw const ProfileValidationException(
        'Ảnh sau khi xử lý vẫn quá lớn. Vui lòng chọn ảnh khác.',
      );
    }

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.set(userRef, {
        'id': user.uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'age': age,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (avatarBytes != null) {
        final avatarRef = _firestore.collection('userAvatars').doc(user.uid);
        batch.set(avatarRef, {
          'bytes': Blob(avatarBytes),
          'contentType': avatarContentType ?? 'image/jpeg',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await user.updateDisplayName(name.trim());
    } catch (error, stackTrace) {
      _log('updateProfile', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ProfileValidationException(
        'Bạn cần đăng nhập để xem thông tin cá nhân.',
      );
    }
    return user;
  }

  String _fallbackName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return (user.email ?? 'Thành viên').split('@').first;
  }

  void _log(String operation, Object error, StackTrace stackTrace) {
    debugPrint('Profile $operation error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class ProfileValidationException implements Exception {
  final String message;

  const ProfileValidationException(this.message);

  @override
  String toString() => message;
}

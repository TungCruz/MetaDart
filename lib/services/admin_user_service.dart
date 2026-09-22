import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/managed_user.dart';
import 'user_profile_service.dart';

class AdminUserService {
  AdminUserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ManagedUser>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return ManagedUser(
          id: doc.id,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          age: (data['age'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    });
  }

  Future<void> addUser({
    required String name,
    required String email,
    required String phone,
    required int age,
    Uint8List? avatarBytes,
    String? avatarContentType,
  }) async {
    _validateAvatar(avatarBytes);
    DocumentReference<Map<String, dynamic>>? createdReference;
    try {
      await _ensureEmailAvailable(email);
      final reference = await _firestore.collection('users').add({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'age': age,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      createdReference = reference;

      final batch = _firestore.batch();
      batch.update(reference, {'id': reference.id});
      if (avatarBytes != null) {
        _setAvatar(batch, reference.id, avatarBytes, avatarContentType);
      }
      await batch.commit();
    } catch (error, stackTrace) {
      _log('addUser', error, stackTrace);
      if (createdReference != null) {
        try {
          await createdReference.delete();
        } catch (rollbackError, rollbackStackTrace) {
          _log('addUserRollback', rollbackError, rollbackStackTrace);
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateUser({
    required ManagedUser user,
    required String name,
    required String email,
    required String phone,
    required int age,
    Uint8List? avatarBytes,
    String? avatarContentType,
    bool removeAvatar = false,
  }) async {
    _validateAvatar(avatarBytes);
    try {
      await _ensureEmailAvailable(email, exceptUserId: user.id);
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.id);
      batch.update(userRef, {
        'id': user.id,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'age': age,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final avatarRef = _firestore.collection('userAvatars').doc(user.id);
      if (removeAvatar) {
        batch.delete(avatarRef);
      } else if (avatarBytes != null) {
        _setAvatar(batch, user.id, avatarBytes, avatarContentType);
      }
      await batch.commit();
    } catch (error, stackTrace) {
      _log('updateUser', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteUser(ManagedUser user) async {
    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('users').doc(user.id));
      batch.delete(_firestore.collection('userAvatars').doc(user.id));
      await batch.commit();
    } catch (error, stackTrace) {
      _log('deleteUser', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _setAvatar(
    WriteBatch batch,
    String userId,
    Uint8List bytes,
    String? contentType,
  ) {
    batch.set(_firestore.collection('userAvatars').doc(userId), {
      'bytes': Blob(bytes),
      'contentType': contentType ?? 'image/jpeg',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _ensureEmailAvailable(
    String email, {
    String? exceptUserId,
  }) async {
    final normalized = email.trim().toLowerCase();
    final result = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(2)
        .get();
    final duplicate = result.docs.any((doc) => doc.id != exceptUserId);
    if (duplicate) {
      throw const AdminUserException('Email này đã tồn tại trong danh sách.');
    }
  }

  void _validateAvatar(Uint8List? bytes) {
    if (bytes != null && bytes.length > UserProfileService.maxAvatarBytes) {
      throw const AdminUserException(
        'Ảnh quá lớn. Vui lòng chọn ảnh JPG hoặc PNG nhỏ hơn.',
      );
    }
  }

  void _log(String operation, Object error, StackTrace stackTrace) {
    debugPrint('Admin $operation error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class AdminUserException implements Exception {
  final String message;

  const AdminUserException(this.message);

  @override
  String toString() => message;
}

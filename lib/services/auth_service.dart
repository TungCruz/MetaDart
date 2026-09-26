import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const adminUsername = 'admin';
  static const _adminEmail = 'admin@metacinema.app';
  static const _adminBackendPassword = 'admin!';

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error, stackTrace) {
      _log('signOut', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final account = email.trim();
      final isAdminAccount = account.toLowerCase() == adminUsername;
      final credential = await _auth.signInWithEmailAndPassword(
        email: isAdminAccount ? _adminEmail : account,
        password: isAdminAccount && password == adminUsername
            ? _adminBackendPassword
            : password,
      );
      final token = await credential.user?.getIdTokenResult(true);
      if (token?.claims?['admin'] == true) return credential;

      final user = credential.user;
      final profile = user == null
          ? null
          : await _firestore.collection('users').doc(user.uid).get();
      if (profile == null || !profile.exists) {
        await _auth.signOut();
        throw const AccountAccessException(
          'Tài khoản chưa có hồ sơ hợp lệ. Vui lòng liên hệ quản trị viên.',
        );
      }
      final status = profile.data()?['status'] as String? ?? 'active';
      if (status != 'active') {
        await _auth.signOut();
        throw const AccountAccessException(
          'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.',
        );
      }
      return credential;
    } catch (error, stackTrace) {
      _log('signIn', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(forceRefresh);
      if (token.claims?['admin'] == true) return true;
      final profile = await _firestore.collection('users').doc(user.uid).get();
      return profile.data()?['role'] == 'admin';
    } catch (error, stackTrace) {
      _log('isCurrentUserAdmin', error, stackTrace);
      return false;
    }
  }

  Future<bool> mustChangePassword() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final profile = await _firestore.collection('users').doc(user.uid).get();
    return profile.data()?['mustChangePassword'] == true;
  }

  Future<void> changeInitialPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountAccessException('Phiên đăng nhập đã hết hạn.');
    }
    try {
      await user.updatePassword(newPassword);
      await _firestore.collection('users').doc(user.uid).update({
        'mustChangePassword': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      _log('changeInitialPassword', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<UserCredential> register({
    required String name,
    required String phone,
    required String email,
    required int age,
    required String password,
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'age': age,
        'phone': phone.trim(),
        'role': 'user',
        'status': 'active',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (error, stackTrace) {
      _log('register', error, stackTrace);

      // Avoid leaving an Authentication account without a Firestore profile.
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (rollbackError, rollbackStackTrace) {
          _log('registerRollback', rollbackError, rollbackStackTrace);
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (error, stackTrace) {
      _log('sendPasswordResetEmail', error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  String messageFor(Object error) {
    if (error is AccountAccessException) return error.message;
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Email không hợp lệ.',
        'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
        'user-not-found' ||
        'invalid-credential' => 'Email hoặc mật khẩu không chính xác.',
        'wrong-password' => 'Email hoặc mật khẩu không chính xác.',
        'email-already-in-use' => 'Email này đã được đăng ký.',
        'weak-password' => 'Mật khẩu chưa đủ mạnh.',
        'too-many-requests' =>
          'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau.',
        'network-request-failed' =>
          'Không thể kết nối mạng. Vui lòng kiểm tra Internet.',
        _ => error.message ?? 'Firebase Authentication gặp lỗi.',
      };
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => 'Bạn không có quyền thực hiện thao tác này.',
        'unavailable' => 'Không thể kết nối Firestore. Vui lòng thử lại sau.',
        _ => error.message ?? 'Firebase gặp lỗi. Vui lòng thử lại.',
      };
    }

    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  void _log(String operation, Object error, StackTrace stackTrace) {
    debugPrint('Firebase $operation error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class AccountAccessException implements Exception {
  final String message;

  const AccountAccessException(this.message);

  @override
  String toString() => message;
}

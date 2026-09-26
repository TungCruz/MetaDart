import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/managed_user.dart';
import 'user_profile_service.dart';

class AdminUserService {
  AdminUserService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? client,
    String? apiBaseUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client(),
       _apiBaseUrl = apiBaseUrl ?? _defaultApiBaseUrl;

  static const defaultPassword = '123456';
  static String get _defaultApiBaseUrl {
    const configuredApiBaseUrl = String.fromEnvironment('ADMIN_API_BASE_URL');
    if (configuredApiBaseUrl.isNotEmpty) return configuredApiBaseUrl;
    if (kIsWeb) return 'http://localhost:5055';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5055'
        : 'http://localhost:5055';
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _client;
  final String _apiBaseUrl;

  Stream<List<ManagedUser>> watchUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map((doc) {
            final data = doc.data();
            return ManagedUser(
              id: doc.id,
              name: data['name'] as String? ?? '',
              email: data['email'] as String? ?? '',
              phone: data['phone'] as String? ?? '',
              age: (data['age'] as num?)?.toInt() ?? 0,
              status: data['status'] as String? ?? 'active',
              role: data['role'] as String? ?? 'user',
            );
          }).toList();
          users.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return users;
        })
        .handleError((Object error, StackTrace stackTrace) {
          _log('watchUsers', error, stackTrace);
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
    await _request('POST', '/api/admin/users', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'age': age,
      'avatarBase64': avatarBytes == null ? null : base64Encode(avatarBytes),
      'avatarContentType': avatarContentType,
    });
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
    await _request('PUT', '/api/admin/users/${user.id}', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'age': age,
      'avatarBase64': avatarBytes == null ? null : base64Encode(avatarBytes),
      'avatarContentType': avatarContentType,
      'removeAvatar': removeAvatar,
    });
  }

  Future<void> deleteUser(ManagedUser user) async {
    await _request('DELETE', '/api/admin/users/${user.id}', null);
  }

  Future<void> setUserStatus(ManagedUser user, String status) async {
    if (status != 'active' && status != 'disabled') {
      throw const AdminUserException('Trạng thái tài khoản không hợp lệ.');
    }
    await _request('PATCH', '/api/admin/users/${user.id}/status', {
      'status': status,
    });
  }

  Future<void> _request(
    String method,
    String path,
    Map<String, Object?>? body,
  ) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) {
        throw const AdminUserException(
          'Phiên đăng nhập admin đã hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      final request = http.Request(method, Uri.parse('$_apiBaseUrl$path'))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return;

      String message = 'Không thể thực hiện thao tác quản trị.';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          message = 'Tài khoản hiện tại không có quyền quản trị.';
        }
      }
      throw AdminUserException(message);
    } on AdminUserException {
      rethrow;
    } catch (error, stackTrace) {
      _log(method, error, stackTrace);
      throw const AdminUserException(
        'Không kết nối được API quản trị. Hãy kiểm tra backend đang chạy.',
      );
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

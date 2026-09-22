import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final String name;
  final double radius;
  final Uint8List? previewBytes;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.radius = 17,
    this.previewBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (previewBytes != null) return _avatar(previewBytes);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('userAvatars')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final blob = snapshot.data?.data()?['bytes'];
        final bytes = blob is Blob ? blob.bytes : null;
        return _avatar(bytes);
      },
    );
  }

  Widget _avatar(Uint8List? bytes) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE50914),
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? Text(
              _initial(),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }

  String _initial() {
    final source = name.trim().isEmpty ? 'M' : name.trim();
    return source.characters.first.toUpperCase();
  }
}

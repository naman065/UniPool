import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.avgRating,
    required this.totalRatings,
    required this.ridesCompleted,
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final double avgRating;
  final int totalRatings;
  final int ridesCompleted;

  String get displayName {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.contains('@')) {
      return trimmedEmail.split('@').first;
    }

    return 'Student';
  }

  bool get hasRatings => totalRatings > 0;

  String get ratingSummary {
    if (!hasRatings) {
      return 'No ratings yet (0)';
    }

    return '${avgRating.toStringAsFixed(1)}★ ($totalRatings)';
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return UserModel(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?)?.trim().isNotEmpty == true
          ? data['photoUrl'] as String
          : null,
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      ridesCompleted: (data['ridesCompleted'] as num?)?.toInt() ?? 0,
    );
  }

  factory UserModel.fallback(String uid) {
    return UserModel(
      uid: uid,
      name: '',
      email: '',
      photoUrl: null,
      avgRating: 0,
      totalRatings: 0,
      ridesCompleted: 0,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  static const String joinRequestType = 'join_request';
  static const String joinAcceptedType = 'join_accepted';
  static const String memberLeftType = 'member_left';
  static const String genericType = 'generic';

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? rideId;
  final String? senderUid;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.rideId,
    this.senderUid,
  });

  bool get isJoinRequest => type == joinRequestType;

  bool get isJoinAccepted => type == joinAcceptedType;

  bool get isMemberLeft => type == memberLeftType;

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDate;
    try {
      if (data['createdAt'] is Timestamp) {
        parsedDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] != null) {
        parsedDate = DateTime.parse(data['createdAt']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppNotification(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      type: data['type'] ?? genericType,
      isRead: data['isRead'] ?? false,
      createdAt: parsedDate,
      rideId: (data['rideId'] as String?) ?? (data['relatedRideId'] as String?),
      senderUid: data['senderUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (rideId != null) 'rideId': rideId,
      if (rideId != null) 'relatedRideId': rideId,
      if (senderUid != null) 'senderUid': senderUid,
    };
  }
}

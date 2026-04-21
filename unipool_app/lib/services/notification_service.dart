import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipool/models/notification.dart';

class NotificationService {
  static Map<String, dynamic> buildPayload({
    required String title,
    required String body,
    required String type,
    String? rideId,
    String? senderUid,
    dynamic createdAt = const _ServerTimestampPlaceholder(),
  }) {
    final payload = AppNotification(
      id: '',
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      rideId: rideId,
      senderUid: senderUid,
    ).toMap();
    payload['createdAt'] = createdAt is _ServerTimestampPlaceholder
        ? FieldValue.serverTimestamp()
        : createdAt;
    return payload;
  }

  static Future<void> _send(
    String userId,
    String title,
    String body, {
    String? rideId,
    String? senderUid,
    String type = AppNotification.genericType,
  }) async {
    final notification = AppNotification(
      id: '',
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      rideId: rideId,
      senderUid: senderUid,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(
          buildPayload(
            title: notification.title,
            body: notification.body,
            type: notification.type,
            rideId: notification.rideId,
            senderUid: notification.senderUid,
            createdAt: Timestamp.now(),
          ),
        );
  }

  static Future<void> sendRideCanceled(
    List<String> participantIds,
    String destination,
  ) async {
    for (final id in participantIds) {
      await _send(
        id,
        'Ride Canceled',
        'The leader canceled the ride to $destination.',
      );
    }
  }

  static Future<void> sendPassengerJoined(
    String leaderId,
    String passengerName,
    String destination,
  ) async {
    await _send(
      leaderId,
      'New Passenger',
      '$passengerName has joined your ride to $destination.',
    );
  }

  static Future<void> sendRideUpdated(
    List<String> participantIds,
    String destination,
  ) async {
    for (final id in participantIds) {
      await _send(
        id,
        'Ride Updated',
        'The details of your ride to $destination have been modified by the leader.',
      );
    }
  }

  static Future<void> sendJoinAccepted({
    required String userId,
    required String leaderUid,
    required String leaderName,
    required String rideId,
    required String destination,
  }) async {
    await _send(
      userId,
      'Request accepted',
      '$leaderName accepted your request for the ride to $destination.',
      rideId: rideId,
      senderUid: leaderUid,
      type: AppNotification.joinAcceptedType,
    );
  }

  static Future<void> sendMemberLeft({
    required String leaderId,
    required String riderUid,
    required String riderName,
    required String rideId,
    required String destination,
  }) async {
    await _send(
      leaderId,
      'Rider left',
      '$riderName left your ride to $destination.',
      rideId: rideId,
      senderUid: riderUid,
      type: AppNotification.memberLeftType,
    );
  }
}

class _ServerTimestampPlaceholder {
  const _ServerTimestampPlaceholder();
}

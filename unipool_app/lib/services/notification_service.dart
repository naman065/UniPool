import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> _send(String userId, String title, String body, {String? rideId}) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': Timestamp.now(),
      if (rideId != null) 'relatedRideId': rideId,
    });
  }

  static Future<void> sendRideCanceled(List<String> participantIds, String destination) async {
    for (final id in participantIds) {
      await _send(id, 'Ride Canceled', 'The leader canceled the ride to $destination.');
    }
  }

  static Future<void> sendPassengerJoined(String leaderId, String passengerName, String destination) async {
    await _send(leaderId, 'New Passenger', '$passengerName has joined your ride to $destination.');
  }

  static Future<void> sendRideUpdated(List<String> participantIds, String destination) async {
    for (final id in participantIds) {
      await _send(id, 'Ride Updated', 'The details of your ride to $destination have been modified by the leader.');
    }
  }
}

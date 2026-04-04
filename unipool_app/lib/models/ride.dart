import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String source;
  final String destination;
  final DateTime rideDate;
  final String? rideTime;
  final String? fare;
  final String leaderId;
  final String leaderName;
  final String status;
  final List<String> participants;
  final int maxParticipants;

  Ride({
    required this.id,
    required this.source,
    required this.destination,
    required this.rideDate,
    required this.leaderId,
    required this.leaderName,
    required this.status,
    required this.participants,
    required this.maxParticipants,
    this.rideTime,
    this.fare,
  });

  /// Factory constructor to safely parse raw Firestore JSON data.
  factory Ride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDate;
    try {
      parsedDate = data['rideDate'] != null 
          ? DateTime.parse(data['rideDate']) 
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Ride(
      id: doc.id,
      source: data['source'] ?? 'Unknown',
      destination: data['destination'] ?? 'Unknown',
      rideDate: parsedDate,
      leaderId: data['leaderId'] ?? '',
      leaderName: data['leaderName'] ?? 'Student',
      status: data['status'] ?? 'open',
      participants: data.containsKey('participants') 
          ? List<String>.from(data['participants']) 
          : [],
      maxParticipants: data['maxParticipants'] ?? 4,
      rideTime: data['rideTime'],
      fare: data['fare'],
    );
  }

  /// True if the ride is still marked as 'open'
  bool get isOpen => status == 'open';

  /// Total number of passengers who have joined the ride
  int get participantCount => participants.length;

  /// Converts the Ride object back into a Map for saving to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'destination': destination,
      'rideDate': rideDate.toIso8601String(),
      'leaderId': leaderId,
      'leaderName': leaderName,
      'status': status,
      'participants': participants,
      'maxParticipants': maxParticipants,
      if (rideTime != null && rideTime!.isNotEmpty) 'rideTime': rideTime,
      if (fare != null && fare!.isNotEmpty) 'fare': fare,
    };
  }
}

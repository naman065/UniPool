import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus { searching, ongoing, completed }

extension RideStatusX on RideStatus {
  String get value => name;

  String get label {
    switch (this) {
      case RideStatus.searching:
        return 'searching';
      case RideStatus.ongoing:
        return 'ongoing';
      case RideStatus.completed:
        return 'completed';
    }
  }

  static RideStatus fromValue(String? value) {
    switch (value) {
      case 'open':
      case 'searching':
        return RideStatus.searching;
      case 'ongoing':
        return RideStatus.ongoing;
      case 'completed':
        return RideStatus.completed;
      default:
        return RideStatus.searching;
    }
  }
}

enum RideMembershipStatus { none, pending, accepted, rejected, leader }

class Ride {
  final String id;
  final String source;
  final String destination;
  final DateTime rideDate;
  final String? rideTime;
  final String? fare;
  final String leaderId;
  final String leaderName;
  final RideStatus status;
  final List<String> pendingRequests;
  final List<String> acceptedMembers;
  final List<String> rejectedMembers;
  final int maxSeats;
  final DateTime? createdAt;

  const Ride({
    required this.id,
    required this.source,
    required this.destination,
    required this.rideDate,
    required this.leaderId,
    required this.leaderName,
    required this.status,
    required this.pendingRequests,
    required this.acceptedMembers,
    required this.rejectedMembers,
    required this.maxSeats,
    this.rideTime,
    this.fare,
    this.createdAt,
  });

  factory Ride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

    return Ride(
      id: doc.id,
      source: (data['source'] as String?)?.trim().isNotEmpty == true
          ? data['source'] as String
          : 'Unknown',
      destination: (data['destination'] as String?)?.trim().isNotEmpty == true
          ? data['destination'] as String
          : 'Unknown',
      rideDate: _parseDate(data['rideDate']),
      leaderId: (data['leaderId'] as String?) ?? '',
      leaderName: (data['leaderName'] as String?)?.trim().isNotEmpty == true
          ? data['leaderName'] as String
          : 'Student',
      status: RideStatusX.fromValue(data['status'] as String?),
      pendingRequests: _parseStringList(data['pendingRequests']),
      acceptedMembers: _parseStringList(
        data['acceptedMembers'] ?? data['participants'],
      ),
      rejectedMembers: _parseStringList(data['rejectedMembers']),
      maxSeats:
          (data['maxSeats'] as num?)?.toInt() ??
          (data['maxParticipants'] as num?)?.toInt() ??
          4,
      rideTime: data['rideTime'] as String?,
      fare: data['fare'] as String?,
      createdAt: _parseNullableDate(data['createdAt']),
    );
  }

  bool get isOpen => status == RideStatus.searching;

  bool get isSearching => status == RideStatus.searching;

  bool get isOngoing => status == RideStatus.ongoing;

  bool get isCompleted => status == RideStatus.completed;

  int get participantCount => acceptedMembers.length;

  int get maxParticipants => maxSeats;

  List<String> get participants => acceptedMembers;

  bool get hasAvailableSeats => participantCount < maxSeats;

  List<String> get allParticipantIds {
    final ids = <String>{leaderId, ...acceptedMembers};
    ids.removeWhere((id) => id.trim().isEmpty);
    return ids.toList();
  }

  RideMembershipStatus membershipStatusFor(String uid) {
    if (uid == leaderId) {
      return RideMembershipStatus.leader;
    }
    if (acceptedMembers.contains(uid)) {
      return RideMembershipStatus.accepted;
    }
    if (pendingRequests.contains(uid)) {
      return RideMembershipStatus.pending;
    }
    if (rejectedMembers.contains(uid)) {
      return RideMembershipStatus.rejected;
    }
    return RideMembershipStatus.none;
  }

  bool includesUser(String uid) {
    final status = membershipStatusFor(uid);
    return status == RideMembershipStatus.leader ||
        status == RideMembershipStatus.accepted;
  }

  Ride copyWith({
    String? id,
    String? source,
    String? destination,
    DateTime? rideDate,
    String? rideTime,
    String? fare,
    String? leaderId,
    String? leaderName,
    RideStatus? status,
    List<String>? pendingRequests,
    List<String>? acceptedMembers,
    List<String>? rejectedMembers,
    int? maxSeats,
    DateTime? createdAt,
  }) {
    return Ride(
      id: id ?? this.id,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      rideDate: rideDate ?? this.rideDate,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      status: status ?? this.status,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      acceptedMembers: acceptedMembers ?? this.acceptedMembers,
      rejectedMembers: rejectedMembers ?? this.rejectedMembers,
      maxSeats: maxSeats ?? this.maxSeats,
      rideTime: rideTime ?? this.rideTime,
      fare: fare ?? this.fare,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'destination': destination,
      'rideDate': rideDate.toIso8601String(),
      'leaderId': leaderId,
      'leaderName': leaderName,
      'status': status.value,
      'pendingRequests': pendingRequests,
      'acceptedMembers': acceptedMembers,
      'participants': acceptedMembers,
      'rejectedMembers': rejectedMembers,
      'maxSeats': maxSeats,
      'maxParticipants': maxSeats,
      if (rideTime != null && rideTime!.isNotEmpty) 'rideTime': rideTime,
      if (fare != null && fare!.isNotEmpty) 'fare': fare,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  static DateTime _parseDate(dynamic value) {
    return _parseNullableDate(value) ?? DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .whereType<Object?>()
          .map((item) => item?.toString() ?? '')
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    return <String>[];
  }
}

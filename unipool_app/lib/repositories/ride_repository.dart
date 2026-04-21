import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipool/models/notification.dart';
import 'package:unipool/models/ride.dart';

class RideRepository {
  RideRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _notificationsFor(String userId) {
    return _users.doc(userId).collection('notifications');
  }

  Stream<Ride?> watchRide(String rideId) {
    return _rides.doc(rideId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return Ride.fromFirestore(snapshot);
    });
  }

  Stream<List<Ride>> watchSearchingRides({String? destination}) {
    Query<Map<String, dynamic>> query = _rides;
    if (destination != null && destination.trim().isNotEmpty) {
      query = query.where('destination', isEqualTo: destination);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(Ride.fromFirestore)
              .where((ride) => ride.isSearching)
              .toList()
            ..sort((a, b) => a.rideDate.compareTo(b.rideDate)),
    );
  }

  Stream<List<Ride>> watchLeaderRides(String leaderUid) {
    return _rides
        .where('leaderId', isEqualTo: leaderUid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Ride.fromFirestore).toList()
                ..sort((a, b) => b.rideDate.compareTo(a.rideDate)),
        );
  }

  Stream<List<Ride>> watchJoinedRides(String userUid) {
    return _rides
        .where('participants', arrayContains: userUid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Ride.fromFirestore).toList()
                ..sort((a, b) => b.rideDate.compareTo(a.rideDate)),
        );
  }

  Stream<Map<String, double>> watchRatingsByAuthor({
    required String rideId,
    required String fromUid,
  }) {
    return _rides
        .doc(rideId)
        .collection('ratings')
        .where('fromUid', isEqualTo: fromUid)
        .snapshots()
        .map((snapshot) {
          final result = <String, double>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final toUid = data['toUid'] as String?;
            if (toUid == null || toUid.isEmpty) {
              continue;
            }
            result[toUid] = (data['rating'] as num?)?.toDouble() ?? 0;
          }
          return result;
        });
  }

  Future<String> createRide(Ride ride) async {
    final doc = _rides.doc();
    await doc.set(ride.copyWith(id: doc.id, createdAt: DateTime.now()).toMap());
    return doc.id;
  }

  Future<void> updateRide(Ride ride) async {
    await _rides.doc(ride.id).update(ride.toMap());
  }

  Future<void> deleteRide(String rideId) async {
    await _rides.doc(rideId).delete();
  }

  Future<void> requestToJoin({
    required String rideId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final rideRef = _rides.doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        throw StateError('Ride not found.');
      }

      final ride = Ride.fromFirestore(rideSnapshot);
      final membershipStatus = ride.membershipStatusFor(userId);

      if (!ride.isSearching) {
        throw StateError('This ride is no longer taking join requests.');
      }
      if (membershipStatus == RideMembershipStatus.leader ||
          membershipStatus == RideMembershipStatus.accepted) {
        return;
      }
      if (membershipStatus == RideMembershipStatus.pending) {
        throw StateError('Your join request is already pending.');
      }
      if (membershipStatus == RideMembershipStatus.rejected) {
        throw StateError('Your previous request was rejected by the leader.');
      }

      final updatedPending = <String>[...ride.pendingRequests, userId];
      final senderRef = _users.doc(userId);
      final senderSnapshot = await transaction.get(senderRef);
      final senderData = senderSnapshot.data() ?? <String, dynamic>{};
      final senderName = (senderData['name'] as String?)?.trim();
      final fallbackName = (senderData['email'] as String?)?.split('@').first;
      final displayName = (senderName?.isNotEmpty ?? false)
          ? senderName!
          : (fallbackName?.isNotEmpty ?? false ? fallbackName! : 'A rider');
      final leaderNotificationRef = _notificationsFor(ride.leaderId).doc();

      transaction.update(rideRef, {'pendingRequests': updatedPending});
      transaction.set(leaderNotificationRef, {
        'title': 'New join request',
        'body': '$displayName wants to join your ride to ${ride.destination}.',
        'type': AppNotification.joinRequestType,
        'senderUid': userId,
        'rideId': ride.id,
        'relatedRideId': ride.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> acceptMember({
    required String rideId,
    required String leaderUid,
    required String memberUid,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final rideRef = _rides.doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        throw StateError('Ride not found.');
      }

      final ride = Ride.fromFirestore(rideSnapshot);

      if (ride.leaderId != leaderUid) {
        throw StateError('Only the leader can approve riders.');
      }
      if (!ride.pendingRequests.contains(memberUid)) {
        throw StateError('This request is no longer pending.');
      }
      if (ride.acceptedMembers.length >= ride.maxSeats) {
        throw StateError('All seats are already filled.');
      }

      final updatedPending = List<String>.from(ride.pendingRequests)
        ..remove(memberUid);
      final updatedAccepted = List<String>.from(ride.acceptedMembers)
        ..add(memberUid);

      transaction.update(rideRef, {
        'pendingRequests': updatedPending,
        'acceptedMembers': updatedAccepted,
        'participants': updatedAccepted,
        'rejectedMembers': List<String>.from(ride.rejectedMembers)
          ..remove(memberUid),
      });
    });
  }

  Future<void> rejectMember({
    required String rideId,
    required String leaderUid,
    required String memberUid,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final rideRef = _rides.doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        throw StateError('Ride not found.');
      }

      final ride = Ride.fromFirestore(rideSnapshot);

      if (ride.leaderId != leaderUid) {
        throw StateError('Only the leader can reject riders.');
      }

      final updatedPending = List<String>.from(ride.pendingRequests)
        ..remove(memberUid);
      final updatedRejected = List<String>.from(ride.rejectedMembers);
      if (!updatedRejected.contains(memberUid)) {
        updatedRejected.add(memberUid);
      }

      transaction.update(rideRef, {
        'pendingRequests': updatedPending,
        'rejectedMembers': updatedRejected,
      });
    });
  }

  Future<void> leaveRide({
    required String rideId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final rideRef = _rides.doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        throw StateError('Ride not found.');
      }

      final ride = Ride.fromFirestore(rideSnapshot);
      if (ride.isCompleted) {
        throw StateError('Completed rides can no longer be changed.');
      }

      final updatedAccepted = List<String>.from(ride.acceptedMembers)
        ..remove(userId);

      transaction.update(rideRef, {
        'acceptedMembers': updatedAccepted,
        'participants': updatedAccepted,
      });
    });
  }

  Future<void> markRideCompleted({
    required String rideId,
    required String leaderUid,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final rideRef = _rides.doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        throw StateError('Ride not found.');
      }

      final ride = Ride.fromFirestore(rideSnapshot);
      if (ride.leaderId != leaderUid) {
        throw StateError('Only the leader can complete this ride.');
      }
      if (ride.isCompleted) {
        return;
      }

      final leaderRef = _users.doc(leaderUid);
      transaction.update(rideRef, {'status': RideStatus.completed.value});
      transaction.update(leaderRef, {
        'ridesCompleted': FieldValue.increment(1),
      });
    });
  }

  Future<void> submitRating({
    required String rideId,
    required String fromUid,
    required String toUid,
    required double rating,
  }) async {
    if (rating < 1 || rating > 5) {
      throw StateError('Ratings must be between 1 and 5.');
    }
    if (fromUid == toUid) {
      throw StateError('You cannot rate yourself.');
    }

    final rideRef = _rides.doc(rideId);
    final ratingRef = rideRef
        .collection('ratings')
        .doc(buildRatingId(rideId: rideId, fromUid: fromUid, toUid: toUid));
    final targetUserRef = _users.doc(toUid);

    await _firestore.runTransaction((transaction) async {
      final rideSnapshot = await transaction.get(rideRef);
      if (!rideSnapshot.exists) {
        throw StateError('Ride not found.');
      }

      final ride = Ride.fromFirestore(rideSnapshot);
      if (!ride.isCompleted) {
        throw StateError('Ratings open only after the ride is completed.');
      }

      final participants = ride.allParticipantIds.toSet();
      if (!participants.contains(fromUid) || !participants.contains(toUid)) {
        throw StateError('Only ride participants can rate each other.');
      }

      final ratingSnapshot = await transaction.get(ratingRef);
      if (ratingSnapshot.exists) {
        throw StateError('You have already rated this rider for this trip.');
      }

      final targetUserSnapshot = await transaction.get(targetUserRef);
      final targetData = targetUserSnapshot.data() ?? <String, dynamic>{};
      final previousTotal = (targetData['totalRatings'] as num?)?.toInt() ?? 0;
      final previousSum = (targetData['ratingSum'] as num?)?.toDouble() ?? 0;
      final newTotal = previousTotal + 1;
      final newSum = previousSum + rating;
      final newAverage = newSum / newTotal;

      transaction.set(ratingRef, {
        'rideId': rideId,
        'fromUid': fromUid,
        'toUid': toUid,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(targetUserRef, {
        'ratingSum': newSum,
        'totalRatings': newTotal,
        'avgRating': double.parse(newAverage.toStringAsFixed(2)),
      }, SetOptions(merge: true));
    });
  }

  String buildRatingId({
    required String rideId,
    required String fromUid,
    required String toUid,
  }) {
    return '${rideId}_${fromUid}_$toUid';
  }
}

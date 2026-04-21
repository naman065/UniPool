import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/models/user_model.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, UserModel> _userCache = <String, UserModel>{};

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  Future<UserModel?> fetchUser(
    String uid, {
    bool forceRefresh = false,
  }) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      return null;
    }

    if (!forceRefresh && _userCache.containsKey(trimmedUid)) {
      return _userCache[trimmedUid];
    }

    final snapshot = await _users.doc(trimmedUid).get();
    if (!snapshot.exists) {
      final fallback = UserModel.fallback(trimmedUid);
      _userCache[trimmedUid] = fallback;
      return fallback;
    }

    final user = UserModel.fromFirestore(snapshot);
    _userCache[trimmedUid] = user;
    return user;
  }

  Stream<UserModel?> watchUser(String uid) {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      return Stream.value(null);
    }

    return _users.doc(trimmedUid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        final fallback = UserModel.fallback(trimmedUid);
        _userCache[trimmedUid] = fallback;
        return fallback;
      }

      final user = UserModel.fromFirestore(snapshot);
      _userCache[trimmedUid] = user;
      return user;
    });
  }

  Future<List<UserModel>> fetchUsers(
    Iterable<String> uids, {
    bool forceRefresh = false,
  }) async {
    final orderedIds = _orderedUniqueIds(uids);
    if (orderedIds.isEmpty) {
      return const <UserModel>[];
    }

    final missingIds = <String>[];
    for (final uid in orderedIds) {
      if (forceRefresh || !_userCache.containsKey(uid)) {
        missingIds.add(uid);
      }
    }

    for (final chunk in _chunkIds(missingIds, 10)) {
      final snapshot = await _users
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        _userCache[doc.id] = UserModel.fromFirestore(doc);
      }
    }

    return orderedIds.map((uid) {
      final cachedUser = _userCache[uid];
      if (cachedUser != null) {
        return cachedUser;
      }

      final fallback = UserModel.fallback(uid);
      _userCache[uid] = fallback;
      return fallback;
    }).toList();
  }

  Future<bool> canAccessRideProfile({
    required String rideId,
    required String viewerUid,
    required String targetUid,
  }) async {
    if (viewerUid.trim().isEmpty || targetUid.trim().isEmpty) {
      return false;
    }
    if (viewerUid == targetUid) {
      return true;
    }

    final rideSnapshot = await _rides.doc(rideId).get();
    if (!rideSnapshot.exists) {
      return false;
    }

    final ride = Ride.fromFirestore(rideSnapshot);
    final isLeader = ride.leaderId == viewerUid;
    final isAcceptedMember = ride.acceptedMembers.contains(viewerUid);

    if (isLeader) {
      return targetUid == ride.leaderId ||
          ride.pendingRequests.contains(targetUid) ||
          ride.acceptedMembers.contains(targetUid);
    }

    if (!isAcceptedMember) {
      return false;
    }

    return targetUid == ride.leaderId || ride.acceptedMembers.contains(targetUid);
  }

  List<String> _orderedUniqueIds(Iterable<String> uids) {
    final seen = <String>{};
    final ordered = <String>[];

    for (final uid in uids) {
      final trimmedUid = uid.trim();
      if (trimmedUid.isEmpty || !seen.add(trimmedUid)) {
        continue;
      }
      ordered.add(trimmedUid);
    }

    return ordered;
  }

  Iterable<List<String>> _chunkIds(List<String> ids, int size) sync* {
    for (var index = 0; index < ids.length; index += size) {
      final end = (index + size > ids.length) ? ids.length : index + size;
      yield ids.sublist(index, end);
    }
  }
}

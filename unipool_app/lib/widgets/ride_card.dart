import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/models/user_model.dart';
import 'package:unipool/providers/ride_repository_scope.dart';
import 'package:unipool/providers/user_repository_scope.dart';
import 'package:unipool/screens/chat_screen.dart';
import 'package:unipool/screens/member_profile_screen.dart';
import 'package:unipool/screens/rating_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/widgets/member_profile_tile.dart';

abstract class BaseRideCard extends StatelessWidget {
  const BaseRideCard({super.key, required this.ride, this.onTap});

  final Ride ride;
  final VoidCallback? onTap;

  Widget buildPrimaryIcon(BuildContext context) {
    return const AppIconBadge(
      icon: Icons.local_taxi_rounded,
      color: AppColors.primary,
    );
  }

  Widget buildStatusPill(BuildContext context) {
    final color = ride.isOpen ? AppColors.success : AppColors.muted;
    final bgColor = ride.isOpen ? const Color(0xFFE7F7EC) : AppColors.surface;

    return AppPill(
      label: ride.status.label.toUpperCase(),
      foregroundColor: color,
      backgroundColor: ride.isOpen ? bgColor : color.withValues(alpha: 0.12),
    );
  }

  Widget buildRouteDetails(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ride.source} to ${ride.destination}',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, d MMM yyyy').format(ride.rideDate),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoPills(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppPill(
          label: ride.leaderName.isEmpty ? 'Student' : ride.leaderName,
          icon: Icons.person_outline_rounded,
        ),
        if (ride.rideTime != null && ride.rideTime!.isNotEmpty)
          AppPill(label: ride.rideTime!, icon: Icons.schedule_rounded),
        if (ride.fare != null && ride.fare!.isNotEmpty)
          AppPill(label: ride.fare!, icon: Icons.payments_rounded),
        AppPill(
          label: ride.participantCount >= ride.maxParticipants
              ? 'FULL (${ride.participantCount}/${ride.maxParticipants})'
              : '${ride.participantCount}/${ride.maxParticipants} joined',
          icon: Icons.group_rounded,
          foregroundColor: ride.participantCount >= ride.maxParticipants
              ? Colors.white
              : AppColors.primary,
          backgroundColor: ride.participantCount >= ride.maxParticipants
              ? AppColors.danger
              : AppColors.primary.withValues(alpha: 0.12),
        ),
      ],
    );
  }

  Widget? buildBottomAction(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildPrimaryIcon(context),
                  const SizedBox(width: 14),
                  buildRouteDetails(context),
                  buildStatusPill(context),
                ],
              ),
              const SizedBox(height: 16),
              buildInfoPills(context),
              if (buildBottomAction(context) != null) ...[
                const SizedBox(height: 14),
                buildBottomAction(context)!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StandardRideCard extends BaseRideCard {
  const StandardRideCard({super.key, required super.ride, super.onTap});

  @override
  Widget? buildBottomAction(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Tap to review the ride and request a seat',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Spacer(),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.primary,
          size: 14,
        ),
      ],
    );
  }
}

class MyRideCard extends BaseRideCard {
  const MyRideCard({
    super.key,
    required super.ride,
    required this.isLeaderView,
    super.onTap,
  });

  final bool isLeaderView;

  @override
  Widget buildPrimaryIcon(BuildContext context) {
    return AppIconBadge(
      icon: isLeaderView ? Icons.local_taxi_rounded : Icons.group_outlined,
      color: isLeaderView ? AppColors.primary : AppColors.secondary,
    );
  }

  @override
  Widget buildInfoPills(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppPill(
          label: isLeaderView ? 'You are leading' : 'Joined ride',
          icon: isLeaderView
              ? Icons.workspace_premium_outlined
              : Icons.verified_user_outlined,
        ),
        AppPill(
          label: ride.leaderName.isEmpty ? 'Student' : ride.leaderName,
          icon: Icons.person_outline_rounded,
        ),
        if (ride.rideTime != null && ride.rideTime!.isNotEmpty)
          AppPill(label: ride.rideTime!, icon: Icons.schedule_rounded),
        if (ride.fare != null && ride.fare!.isNotEmpty)
          AppPill(label: ride.fare!, icon: Icons.payments_rounded),
        AppPill(
          label: ride.participantCount >= ride.maxParticipants
              ? 'FULL (${ride.participantCount}/${ride.maxParticipants})'
              : '${ride.participantCount}/${ride.maxParticipants} joined',
          icon: Icons.group_rounded,
          foregroundColor: ride.participantCount >= ride.maxParticipants
              ? Colors.white
              : AppColors.primary,
          backgroundColor: ride.participantCount >= ride.maxParticipants
              ? AppColors.danger
              : AppColors.primary.withValues(alpha: 0.12),
        ),
      ],
    );
  }

  @override
  Widget? buildBottomAction(BuildContext context) {
    return AppPrimaryButton(
      label: 'Open chat',
      icon: Icons.chat_bubble_rounded,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChatScreen(rideId: ride.id, rideDestination: ride.destination),
          ),
        );
      },
    );
  }
}

Future<void> showRideDetailsSheet(BuildContext context, Ride ride) async {
  if (!context.mounted) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RideDetailsSheet(rideId: ride.id),
  );
}

class _RideDetailsSheet extends StatelessWidget {
  const _RideDetailsSheet({required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) {
    final rideRepository = RideRepositoryScope.of(context);
    final userRepository = UserRepositoryScope.of(context);

    return StreamBuilder<Ride?>(
      stream: rideRepository.watchRide(rideId),
      builder: (context, rideSnapshot) {
        if (rideSnapshot.connectionState == ConnectionState.waiting) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AppSurfaceCard(
                radius: 30,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          );
        }

        final ride = rideSnapshot.data;
        if (ride == null) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AppSurfaceCard(
                radius: 30,
                child: AppEmptyState(
                  icon: Icons.route_rounded,
                  title: 'Ride unavailable',
                  subtitle: 'This ride may have been deleted.',
                ),
              ),
            ),
          );
        }

        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final membershipStatus = currentUid == null
            ? RideMembershipStatus.none
            : ride.membershipStatusFor(currentUid);
        final canSeeConfirmedPool =
            membershipStatus == RideMembershipStatus.leader ||
            membershipStatus == RideMembershipStatus.accepted;
        final canOpenProfiles = canSeeConfirmedPool ||
            (currentUid != null && currentUid == ride.leaderId);
        final idsForLookup = <String>[
          ride.leaderId,
          if (canSeeConfirmedPool) ...ride.acceptedMembers,
        ];

        return FutureBuilder<List<UserModel>>(
          future: userRepository.fetchUsers(idsForLookup),
          builder: (context, usersSnapshot) {
            final users = usersSnapshot.data ?? const <UserModel>[];
            final userById = {for (final user in users) user.uid: user};
            final leader =
                userById[ride.leaderId] ??
                UserModel(
                  uid: ride.leaderId,
                  name: ride.leaderName,
                  email: '',
                  photoUrl: null,
                  avgRating: 0,
                  totalRatings: 0,
                  ridesCompleted: 0,
                );
            final confirmedMembers = ride.acceptedMembers
                .map((uid) => userById[uid] ?? UserModel.fallback(uid))
                .toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AppSurfaceCard(
                  radius: 30,
                  padding: const EdgeInsets.all(22),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppIconBadge(
                              icon: Icons.directions_car_filled_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ride details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _DetailRow(
                          label: 'From',
                          value: ride.source,
                          color: AppColors.primary,
                          icon: Icons.my_location_rounded,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: 'To',
                          value: ride.destination,
                          color: AppColors.accent,
                          icon: Icons.place_rounded,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: 'Date',
                          value: DateFormat(
                            'EEEE, d MMM yyyy',
                          ).format(ride.rideDate),
                          color: AppColors.secondary,
                          icon: Icons.calendar_month_rounded,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: 'Status',
                          value: ride.status.label,
                          color: ride.isCompleted
                              ? AppColors.secondary
                              : AppColors.success,
                          icon: ride.isCompleted
                              ? Icons.flag_circle_rounded
                              : Icons.search_rounded,
                        ),
                        if (ride.rideTime != null &&
                            ride.rideTime!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Time',
                            value: ride.rideTime!,
                            color: AppColors.primary,
                            icon: Icons.schedule_rounded,
                          ),
                        ],
                        if (ride.fare != null && ride.fare!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Fare',
                            value: ride.fare!,
                            color: AppColors.success,
                            icon: Icons.payments_rounded,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: 'Seats',
                          value:
                              '${ride.participantCount}/${ride.maxSeats} accepted',
                          color: AppColors.primary,
                          icon: Icons.event_seat_rounded,
                        ),
                        if (ride.participantCount > 0) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Confirmed pool',
                            value: ride.participantCount == 1
                                ? '1 rider confirmed'
                                : '${ride.participantCount} riders confirmed',
                            color: AppColors.accent,
                            icon: Icons.group_rounded,
                          ),
                        ],
                        if (membershipStatus == RideMembershipStatus.leader &&
                            ride.pendingRequests.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Pending',
                            value:
                                '${ride.pendingRequests.length} rider request(s)',
                            color: AppColors.warning,
                            icon: Icons.pending_actions_rounded,
                          ),
                        ],
                        const SizedBox(height: 18),
                        AppSurfaceCard(
                          color: AppColors.surfaceSoft,
                          radius: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppSectionHeader(
                                title: 'Ride leader',
                                subtitle:
                                    'Name, photo, and rating stay visible on every ride listing.',
                              ),
                              const SizedBox(height: 16),
                              MemberProfileTile(
                                user: leader,
                                subtitle: 'Leader',
                                onTap: canOpenProfiles
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                MemberProfileScreen(
                                                  rideId: ride.id,
                                                  memberUid: leader.uid,
                                                ),
                                          ),
                                        );
                                      }
                                    : null,
                                trailing: canOpenProfiles
                                    ? const _ProfileArrow()
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppSurfaceCard(
                          color: AppColors.surfaceSoft,
                          radius: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSectionHeader(
                                title: 'Confirmed pool',
                                subtitle: canSeeConfirmedPool
                                    ? 'Accepted riders can review each other before the trip.'
                                    : 'Confirmed rider profiles unlock after the leader accepts your request.',
                              ),
                              const SizedBox(height: 16),
                              if (canSeeConfirmedPool &&
                                  confirmedMembers.isNotEmpty)
                                ..._buildConfirmedPool(
                                  context,
                                  ride: ride,
                                  confirmedMembers: confirmedMembers,
                                  currentUid: currentUid,
                                )
                              else if (canSeeConfirmedPool)
                                const Text(
                                  'No riders have been accepted yet.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                )
                              else
                                const Text(
                                  'You can already review the leader profile. The rest of the pool becomes visible once you are confirmed for this ride.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _RideActionArea(ride: ride),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildConfirmedPool(
    BuildContext context, {
    required Ride ride,
    required List<UserModel> confirmedMembers,
    required String? currentUid,
  }) {
    final widgets = <Widget>[];

    for (var index = 0; index < confirmedMembers.length; index++) {
      final member = confirmedMembers[index];
      widgets.add(
        MemberProfileTile(
          user: member,
          subtitle: member.uid == currentUid ? 'You' : 'Confirmed rider',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    MemberProfileScreen(rideId: ride.id, memberUid: member.uid),
              ),
            );
          },
          trailing: const _ProfileArrow(),
        ),
      );

      if (index != confirmedMembers.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.line.withValues(alpha: 0.8)),
          ),
        );
      }
    }

    return widgets;
  }
}

class _RideActionArea extends StatelessWidget {
  const _RideActionArea({required this.ride});

  final Ride ride;

  Future<void> _requestToJoin(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      await RideRepositoryScope.of(
        context,
      ).requestToJoin(rideId: ride.id, userId: currentUser.uid);
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Join request sent to the leader.',
          isError: false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;
    if (currentUid == null) {
      return const SizedBox.shrink();
    }

    final membershipStatus = ride.membershipStatusFor(currentUid);

    switch (membershipStatus) {
      case RideMembershipStatus.leader:
      case RideMembershipStatus.accepted:
        if (ride.isCompleted) {
          return AppPrimaryButton(
            label: 'Rate participants',
            icon: Icons.star_rate_rounded,
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RatingScreen(rideId: ride.id),
                ),
              );
            },
          );
        }

        return AppPrimaryButton(
          label: 'Open chat',
          icon: Icons.chat_bubble_rounded,
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  rideId: ride.id,
                  rideDestination: ride.destination,
                ),
              ),
            );
          },
        );
      case RideMembershipStatus.pending:
        return const AppPill(
          label: 'Your request is pending leader approval',
          icon: Icons.hourglass_top_rounded,
          foregroundColor: AppColors.warning,
          backgroundColor: Color(0xFF182543),
        );
      case RideMembershipStatus.rejected:
        return const AppPill(
          label: 'Your previous request was rejected',
          icon: Icons.block_rounded,
          foregroundColor: AppColors.danger,
          backgroundColor: Color(0xFF21151A),
        );
      case RideMembershipStatus.none:
        if (!ride.isSearching) {
          return const AppPill(
            label: 'This ride is no longer accepting requests',
            icon: Icons.info_outline_rounded,
            foregroundColor: AppColors.muted,
            backgroundColor: Color(0xFF182543),
          );
        }
        if (!ride.hasAvailableSeats) {
          return const AppPill(
            label: 'No seats available right now',
            icon: Icons.event_busy_rounded,
            foregroundColor: AppColors.danger,
            backgroundColor: Color(0xFF21151A),
          );
        }
        return AppPrimaryButton(
          label: 'Request to join',
          icon: Icons.person_add_alt_rounded,
          onPressed: () => _requestToJoin(context),
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconBadge(icon: icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileArrow extends StatelessWidget {
  const _ProfileArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.primary,
        size: 14,
      ),
    );
  }
}

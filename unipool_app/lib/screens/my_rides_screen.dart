import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/providers/ride_repository_scope.dart';
import 'package:unipool/screens/create_ride_screen.dart';
import 'package:unipool/screens/rating_screen.dart';
import 'package:unipool/screens/ride_requests_screen.dart';
import 'package:unipool/services/notification_service.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/widgets/ride_card.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: AppGradientBackground(
          useSafeArea: false,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppPageHeader(
                  title: 'My rides',
                  subtitle: 'Rides you lead, join, approve, and rate.',
                  leading: _TopBackButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  badge: const AppPill(
                    label: 'My activity',
                    icon: Icons.route_rounded,
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0x33FFFFFF),
                  ),
                  bottom: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1629),
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Color(0xFFB3C0DB),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      indicator: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_taxi_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('I am leading'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('I joined'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      RideList(isLeader: true),
                      RideList(isLeader: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RideList extends StatelessWidget {
  const RideList({super.key, required this.isLeader});

  final bool isLeader;

  Future<void> _completeRide(
    BuildContext context,
    Ride ride,
    String leaderId,
  ) async {
    try {
      await RideRepositoryScope.of(
        context,
      ).markRideCompleted(rideId: ride.id, leaderUid: leaderId);

      if (context.mounted) {
        showAppSnackBar(context, 'Ride marked as completed.', isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Unable to complete ride: $e', isError: true);
      }
    }
  }

  Future<void> _deleteRide(BuildContext context, Ride ride) async {
    final rideRepository = RideRepositoryScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete ride?'),
          content: const Text(
            'This will cancel the ride and remove it for everyone. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      if (ride.acceptedMembers.isNotEmpty) {
        await NotificationService.sendRideCanceled(
          ride.acceptedMembers,
          ride.destination,
        );
      }
      await rideRepository.deleteRide(ride.id);
      if (context.mounted) {
        showAppSnackBar(context, 'Ride deleted successfully.', isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Error deleting ride: $e', isError: true);
      }
    }
  }

  Future<void> _leaveRide(
    BuildContext context,
    Ride ride,
    String userId,
  ) async {
    final rideRepository = RideRepositoryScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Leave ride?'),
          content: const Text(
            'Are you sure you want to drop out of this ride?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Leave',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await rideRepository.leaveRide(rideId: ride.id, userId: userId);
      if (context.mounted) {
        showAppSnackBar(context, 'You have left the ride.', isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Error leaving ride: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final rideRepository = RideRepositoryScope.of(context);
    final stream = isLeader
        ? rideRepository.watchLeaderRides(user.uid)
        : rideRepository.watchJoinedRides(user.uid);

    return StreamBuilder<List<Ride>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final rides = List<Ride>.from(snapshot.data ?? const <Ride>[]);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        rides.removeWhere((ride) {
          final rideDay = DateTime(
            ride.rideDate.year,
            ride.rideDate.month,
            ride.rideDate.day,
          );
          final isPastUnfinished = rideDay.isBefore(today) && !ride.isCompleted;

          if (isPastUnfinished) {
            return true;
          }
          if (!isLeader && ride.leaderId == user.uid) {
            return true;
          }
          return false;
        });

        rides.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return b.rideDate.compareTo(a.rideDate);
        });

        if (rides.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: AppEmptyState(
              icon: isLeader
                  ? Icons.local_taxi_rounded
                  : Icons.travel_explore_rounded,
              title: isLeader ? 'No rides posted yet' : 'No joined rides yet',
              subtitle: isLeader
                  ? 'Create a ride from the home screen.'
                  : 'Join a ride to see it here.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];

            if (isLeader) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _LeaderRideCard(
                  ride: ride,
                  isLeaderView: true,
                  onTap: () => showRideDetailsSheet(context, ride),
                  onComplete: () => _completeRide(context, ride, user.uid),
                  onDelete: () => _deleteRide(context, ride),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateRideScreen(existingRide: ride),
                    ),
                  ),
                  onManageRequests: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RideRequestsScreen(rideId: ride.id),
                    ),
                  ),
                  onRate: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RatingScreen(rideId: ride.id),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _JoinedRideCard(
                ride: ride,
                isLeaderView: false,
                onTap: () => showRideDetailsSheet(context, ride),
                onLeave: () => _leaveRide(context, ride, user.uid),
                onRate: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RatingScreen(rideId: ride.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LeaderRideCard extends MyRideCard {
  const _LeaderRideCard({
    required super.ride,
    required super.isLeaderView,
    super.onTap,
    required this.onComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onManageRequests,
    required this.onRate,
  });

  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onManageRequests;
  final VoidCallback onRate;

  @override
  Widget? buildBottomAction(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        super.buildBottomAction(context) ?? const SizedBox.shrink(),
        if (!ride.isCompleted)
          FilledButton.icon(
            onPressed: onManageRequests,
            icon: const Icon(Icons.how_to_reg_rounded),
            label: Text(
              ride.pendingRequests.isEmpty
                  ? 'Manage requests'
                  : 'Requests (${ride.pendingRequests.length})',
            ),
          ),
        if (!ride.isCompleted)
          FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Mark complete'),
          ),
        if (ride.isCompleted)
          OutlinedButton.icon(
            onPressed: onRate,
            icon: const Icon(
              Icons.star_outline_rounded,
              color: AppColors.primary,
            ),
            label: const Text(
              'Rate riders',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        if (!ride.isCompleted)
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            label: const Text(
              'Edit',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
          ),
          label: const Text(
            'Delete',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

class _JoinedRideCard extends MyRideCard {
  const _JoinedRideCard({
    required super.ride,
    required super.isLeaderView,
    super.onTap,
    required this.onLeave,
    required this.onRate,
  });

  final VoidCallback onLeave;
  final VoidCallback onRate;

  @override
  Widget? buildBottomAction(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        super.buildBottomAction(context) ?? const SizedBox.shrink(),
        if (ride.isCompleted)
          FilledButton.icon(
            onPressed: onRate,
            icon: const Icon(Icons.star_rate_rounded),
            label: const Text('Rate peers'),
          ),
        if (!ride.isCompleted)
          OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(
              Icons.exit_to_app_rounded,
              color: AppColors.danger,
            ),
            label: const Text(
              'Leave ride',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

class _TopBackButton extends StatelessWidget {
  const _TopBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

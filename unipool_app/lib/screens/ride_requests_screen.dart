import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/models/user_model.dart';
import 'package:unipool/providers/ride_repository_scope.dart';
import 'package:unipool/providers/user_repository_scope.dart';
import 'package:unipool/screens/member_profile_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/widgets/member_profile_tile.dart';

class RideRequestsScreen extends StatelessWidget {
  const RideRequestsScreen({super.key, required this.rideId});

  final String rideId;

  Future<void> _handleDecision(
    BuildContext context, {
    required Ride ride,
    required String memberUid,
    required bool accept,
  }) async {
    final leaderUid = FirebaseAuth.instance.currentUser!.uid;
    final repository = RideRepositoryScope.of(context);

    try {
      if (accept) {
        await repository.acceptMember(
          rideId: ride.id,
          leaderUid: leaderUid,
          memberUid: memberUid,
        );
      } else {
        await repository.rejectMember(
          rideId: ride.id,
          leaderUid: leaderUid,
          memberUid: memberUid,
        );
      }

      if (context.mounted) {
        showAppSnackBar(
          context,
          accept ? 'Member approved successfully.' : 'Member rejected.',
          isError: false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Unable to update request: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideRepository = RideRepositoryScope.of(context);
    final userRepository = UserRepositoryScope.of(context);

    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Join requests',
                subtitle: 'Approve riders before the trip fills up.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Leader approval',
                  icon: Icons.how_to_reg_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: StreamBuilder<Ride?>(
                  stream: rideRepository.watchRide(rideId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final ride = snapshot.data;
                    if (ride == null) {
                      return const AppEmptyState(
                        icon: Icons.route_rounded,
                        title: 'Ride not found',
                        subtitle: 'This ride may have been deleted.',
                      );
                    }

                    if (ride.pendingRequests.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.mark_email_read_outlined,
                        title: 'No pending requests',
                        subtitle: ride.isCompleted
                            ? 'This ride has already finished.'
                            : 'New join requests will appear here in real time.',
                      );
                    }

                    return FutureBuilder<List<UserModel>>(
                      future: userRepository.fetchUsers(ride.pendingRequests),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        final users = userSnapshot.data ?? const <UserModel>[];
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: AppSurfaceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MemberProfileTile(
                                      user: user,
                                      subtitle: user.uid,
                                      trailing: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => MemberProfileScreen(
                                                rideId: ride.id,
                                                memberUid: user.uid,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          color: AppColors.primary,
                                        ),
                                        label: const Text(
                                          'View profile',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: ride.isCompleted
                                                ? null
                                                : () => _handleDecision(
                                                    context,
                                                    ride: ride,
                                                    memberUid: user.uid,
                                                    accept: true,
                                                  ),
                                            icon: const Icon(
                                              Icons.check_rounded,
                                            ),
                                            label: const Text('Accept'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: ride.isCompleted
                                                ? null
                                                : () => _handleDecision(
                                                    context,
                                                    ride: ride,
                                                    memberUid: user.uid,
                                                    accept: false,
                                                  ),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: AppColors.danger,
                                            ),
                                            label: const Text(
                                              'Reject',
                                              style: TextStyle(
                                                color: AppColors.danger,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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

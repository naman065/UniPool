import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unipool/models/user_model.dart';
import 'package:unipool/providers/user_repository_scope.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/widgets/member_profile_tile.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({
    super.key,
    required this.rideId,
    required this.memberUid,
  });

  final String rideId;
  final String memberUid;

  Future<_MemberProfileState> _loadProfile(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const _MemberProfileState.unauthorized();
    }

    final repository = UserRepositoryScope.of(context);
    final canAccess = await repository.canAccessRideProfile(
      rideId: rideId,
      viewerUid: currentUser.uid,
      targetUid: memberUid,
    );

    if (!canAccess) {
      return const _MemberProfileState.unauthorized();
    }

    final user = await repository.fetchUser(memberUid);
    if (user == null) {
      return const _MemberProfileState.missing();
    }

    return _MemberProfileState.loaded(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Member profile',
                subtitle: 'Visible only within this ride context.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Ride privacy',
                  icon: Icons.verified_user_outlined,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: FutureBuilder<_MemberProfileState>(
                  future: _loadProfile(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final state =
                        snapshot.data ?? const _MemberProfileState.missing();
                    if (!state.canAccess) {
                      return const AppEmptyState(
                        icon: Icons.lock_outline_rounded,
                        title: 'Profile hidden',
                        subtitle:
                            'This profile is only available to riders who share this trip.',
                      );
                    }

                    final user = state.user;
                    if (user == null) {
                      return const AppEmptyState(
                        icon: Icons.person_off_rounded,
                        title: 'Profile unavailable',
                        subtitle:
                            'We could not load this rider profile right now.',
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final metricWidth = constraints.maxWidth >= 520
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSurfaceCard(
                                child: MemberProfileTile(
                                  user: user,
                                  subtitle: user.email.isEmpty
                                      ? null
                                      : user.email,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: metricWidth,
                                    child: _MetricCard(
                                      icon: Icons.star_rate_rounded,
                                      color: AppColors.warning,
                                      label: 'Overall rating',
                                      value: user.avgRating.toStringAsFixed(1),
                                    ),
                                  ),
                                  SizedBox(
                                    width: metricWidth,
                                    child: _MetricCard(
                                      icon: Icons.reviews_outlined,
                                      color: AppColors.primary,
                                      label: 'Total ratings',
                                      value: '${user.totalRatings}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _MetricCard(
                                icon: Icons.verified_rounded,
                                color: AppColors.secondary,
                                label: 'Rides completed',
                                value: '${user.ridesCompleted}',
                                fullWidth: true,
                              ),
                              const SizedBox(height: 18),
                              AppSurfaceCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppSectionHeader(
                                      title: 'Rating context',
                                      subtitle:
                                          'Use the full rating count to judge how established this rider is.',
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      user.ratingSummary,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      user.totalRatings == 0
                                          ? 'This rider has not been rated on any completed UniPool trips yet.'
                                          : 'This score is based on ${user.totalRatings} completed-ride rating${user.totalRatings == 1 ? '' : 's'}.',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        children: [
          AppIconBadge(icon: icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: fullWidth ? 26 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberProfileState {
  const _MemberProfileState({
    required this.canAccess,
    this.user,
  });

  const _MemberProfileState.loaded(UserModel user)
    : this(canAccess: true, user: user);

  const _MemberProfileState.unauthorized() : this(canAccess: false);

  const _MemberProfileState.missing() : this(canAccess: true);

  final bool canAccess;
  final UserModel? user;
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

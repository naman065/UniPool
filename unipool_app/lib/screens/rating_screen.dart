import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/models/user_model.dart';
import 'package:unipool/providers/ride_repository_scope.dart';
import 'package:unipool/providers/user_repository_scope.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/widgets/member_profile_tile.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final Map<String, double> _draftRatings = <String, double>{};
  bool _submitting = false;

  Future<void> _submitRatings(
    Ride ride,
    List<UserModel> peers,
    Map<String, double> submittedRatings,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }
    final repository = RideRepositoryScope.of(context);

    final unratedPeers = peers
        .where((peer) => !submittedRatings.containsKey(peer.uid))
        .toList();

    if (unratedPeers.isEmpty) {
      showAppSnackBar(
        context,
        'You have already rated everyone on this ride.',
        isError: false,
      );
      return;
    }

    final missingSelections = unratedPeers.any(
      (peer) => !_draftRatings.containsKey(peer.uid),
    );
    if (missingSelections) {
      showAppSnackBar(
        context,
        'Choose a rating for each rider before submitting.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      for (final peer in unratedPeers) {
        await repository.submitRating(
          rideId: ride.id,
          fromUid: currentUser.uid,
          toUid: peer.uid,
          rating: _draftRatings[peer.uid]!,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        for (final peer in unratedPeers) {
          _draftRatings.remove(peer.uid);
        }
      });
      showAppSnackBar(
        context,
        'Ratings submitted successfully.',
        isError: false,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Unable to submit ratings: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final rideRepository = RideRepositoryScope.of(context);
    final userRepository = UserRepositoryScope.of(context);

    if (currentUser == null) {
      return const Scaffold(
        body: AppGradientBackground(
          child: AppEmptyState(
            icon: Icons.star_outline_rounded,
            title: 'Sign in required',
            subtitle: 'You need an active session to submit ratings.',
          ),
        ),
      );
    }

    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Rate your ride',
                subtitle:
                    'Each participant can rate every other participant once the ride is completed.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Mutual rating',
                  icon: Icons.star_rate_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: StreamBuilder<Ride?>(
                  stream: rideRepository.watchRide(widget.rideId),
                  builder: (context, rideSnapshot) {
                    if (rideSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final ride = rideSnapshot.data;
                    if (ride == null) {
                      return const AppEmptyState(
                        icon: Icons.route_rounded,
                        title: 'Ride not found',
                        subtitle: 'This ride may have been deleted.',
                      );
                    }

                    if (!ride.isCompleted) {
                      return const AppEmptyState(
                        icon: Icons.lock_clock_rounded,
                        title: 'Ratings are locked',
                        subtitle:
                            'Peer ratings become available only after the ride is marked completed.',
                      );
                    }

                    final peerIds = ride.allParticipantIds
                        .where((uid) => uid != currentUser.uid)
                        .toList();

                    if (peerIds.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.star_half_rounded,
                        title: 'No peers to rate',
                        subtitle:
                            'This ride does not have any other participants.',
                      );
                    }

                    return StreamBuilder<Map<String, double>>(
                      stream: rideRepository.watchRatingsByAuthor(
                        rideId: ride.id,
                        fromUid: currentUser.uid,
                      ),
                      builder: (context, ratingsSnapshot) {
                        final submittedRatings =
                            ratingsSnapshot.data ?? const <String, double>{};

                        return FutureBuilder<List<UserModel>>(
                          future: userRepository.fetchUsers(peerIds),
                          builder: (context, peersSnapshot) {
                            if (peersSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            }

                            final peers =
                                peersSnapshot.data ?? const <UserModel>[];

                            return Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      20,
                                      20,
                                      24,
                                    ),
                                    itemCount: peers.length,
                                    itemBuilder: (context, index) {
                                      final peer = peers[index];
                                      final submittedValue =
                                          submittedRatings[peer.uid];
                                      final selectedValue =
                                          _draftRatings[peer.uid] ?? 0;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: AppSurfaceCard(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              MemberProfileTile(
                                                user: peer,
                                                subtitle: submittedValue != null
                                                    ? 'Submitted: ${submittedValue.toStringAsFixed(1)} / 5'
                                                    : 'Select a score from 1 to 5',
                                              ),
                                              Row(
                                                children: [
                                                  const Spacer(),
                                                  AppPill(
                                                    label:
                                                        'Overall ${peer.ratingSummary}',
                                                    icon: Icons
                                                        .star_outline_rounded,
                                                    foregroundColor:
                                                        peer.hasRatings
                                                        ? AppColors.warning
                                                        : AppColors.secondary,
                                                    backgroundColor:
                                                        const Color(0xFF182543),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              _StarRatingBar(
                                                value:
                                                    submittedValue ??
                                                    selectedValue,
                                                enabled: submittedValue == null,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _draftRatings[peer.uid] =
                                                        value;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    24,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: AppPrimaryButton(
                                      label: 'Submit ratings',
                                      icon: Icons.check_rounded,
                                      isLoading: _submitting,
                                      onPressed: _submitting
                                          ? null
                                          : () => _submitRatings(
                                              ride,
                                              peers,
                                              submittedRatings,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
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

class _StarRatingBar extends StatelessWidget {
  const _StarRatingBar({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = value >= starValue;

        return IconButton(
          onPressed: enabled ? () => onChanged(starValue.toDouble()) : null,
          icon: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isFilled ? AppColors.warning : AppColors.muted,
            size: 30,
          ),
        );
      }),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/screens/chat_screen.dart';

/// A base abstract class for a Ride Card. 
/// You can inherit from this class and override specific builder methods
/// to customize how the card is drawn for different scenarios!
abstract class BaseRideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;

  const BaseRideCard({
    super.key,
    required this.ride,
    this.onTap,
  });

  /// Builds the top icon (e.g., taxi or group icon)
  Widget buildPrimaryIcon(BuildContext context) {
    return const AppIconBadge(
      icon: Icons.local_taxi_rounded,
      color: AppColors.primary,
    );
  }

  /// Builds the top right status pill
  Widget buildStatusPill(BuildContext context) {
    final color = ride.isOpen ? AppColors.success : AppColors.muted;
    final bgColor = ride.isOpen ? const Color(0xFFE7F7EC) : AppColors.surface;

    return AppPill(
      label: ride.status.toUpperCase(),
      foregroundColor: color,
      backgroundColor: ride.isOpen ? bgColor : color.withValues(alpha: 0.12),
    );
  }

  /// Builds the main route and date text
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

  /// Builds the wrapping pills for leader, time, fare, and participants
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
          AppPill(
            label: ride.rideTime!,
            icon: Icons.schedule_rounded,
          ),
        if (ride.fare != null && ride.fare!.isNotEmpty)
          AppPill(
            label: ride.fare!,
            icon: Icons.payments_rounded,
          ),
        if (ride.participantCount > 0 || ride.participantCount == 0)
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

  /// Optional bottom widget (like action buttons) that child classes can provide
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

/// The standard implementation used on the Find Ride screen
class StandardRideCard extends BaseRideCard {
  const StandardRideCard({super.key, required super.ride, super.onTap});
  
  @override
  Widget? buildBottomAction(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Tap to review the ride and open chat',
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

/// A specialized implementation used on the My Rides screen 
class MyRideCard extends BaseRideCard {
  final bool isLeaderView;

  const MyRideCard({
    super.key, 
    required super.ride, 
    required this.isLeaderView,
    super.onTap,
  });

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
          icon: isLeaderView ? Icons.workspace_premium_outlined : Icons.verified_user_outlined,
        ),
        AppPill(
          label: ride.leaderName.isEmpty ? 'Student' : ride.leaderName,
          icon: Icons.person_outline_rounded,
        ),
        if (ride.rideTime != null && ride.rideTime!.isNotEmpty)
          AppPill(
            label: ride.rideTime!,
            icon: Icons.schedule_rounded,
          ),
        if (ride.fare != null && ride.fare!.isNotEmpty)
          AppPill(
            label: ride.fare!,
            icon: Icons.payments_rounded,
          ),
        if (ride.participantCount > 0 || ride.participantCount == 0)
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
            builder: (_) => ChatScreen(
              rideId: ride.id,
              rideDestination: ride.destination,
            ),
          ),
        );
      },
    );
  }
}

/// Shared method to show ride details bottom sheet
Future<void> showRideDetailsSheet(BuildContext context, Ride ride) async {
  final leaderData = await FirebaseFirestore.instance
      .collection('users')
      .doc(ride.leaderId)
      .get();
  final leaderMap = leaderData.data();
  final ridesCount = leaderMap?['ridesCompleted'] ?? 0;

  List<String> participantNames = [];
  if (ride.participants.isNotEmpty) {
    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: ride.participants.take(10).toList())
          .get();
      for (var doc in querySnap.docs) {
        final data = doc.data();
        if (data != null && data.containsKey('email')) {
            participantNames.add(data['email'].toString().split('@').first);
        } else {
            participantNames.add('Student');
        }
      }
    } catch (_) {}
  }

  if (!context.mounted) return;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppSurfaceCard(
            radius: 30,
            padding: const EdgeInsets.all(22),
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
                      onPressed: () => Navigator.pop(ctx),
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
                  value: DateFormat('EEEE, d MMM yyyy').format(ride.rideDate),
                  color: AppColors.secondary,
                  icon: Icons.calendar_month_rounded,
                ),
                if (ride.rideTime != null && ride.rideTime!.isNotEmpty) ...[
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
                if (participantNames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Joined',
                    value: participantNames.join(', '),
                    color: AppColors.accent,
                    icon: Icons.group_rounded,
                  ),
                ],
                const SizedBox(height: 18),
                AppSurfaceCard(
                  color: AppColors.surfaceSoft,
                  radius: 24,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          ride.leaderName.isNotEmpty ? ride.leaderName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.leaderName.isEmpty ? 'Student' : ride.leaderName,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$ridesCount rides · Verified',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Open chat',
                  icon: Icons.chat_bubble_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          rideId: ride.id,
                          rideDestination: ride.destination,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
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
      children: [
        AppIconBadge(icon: icon, color: color, size: 16),
        const SizedBox(width: 12),
        Column(
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
      ],
    );
  }
}

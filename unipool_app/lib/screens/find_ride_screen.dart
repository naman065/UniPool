import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:unipool/data/ride_locations.dart';
import 'package:unipool/screens/chat_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/widgets/ride_card.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  String _filterDestination = allLocationsLabel;

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'open');

    if (_filterDestination != allLocationsLabel) {
      query = query.where('destination', isEqualTo: _filterDestination);
    }

    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Find a ride',
                subtitle: 'Browse open rides by destination.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Pooler mode',
                  icon: Icons.travel_explore_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination filter',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Narrow the list when you already know where you want to go.',
                              style: TextStyle(
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _filterDestination,
                              decoration: const InputDecoration(
                                labelText: 'Destination',
                                prefixIcon: Icon(
                                  Icons.filter_list_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              items: [allLocationsLabel, ...rideLocations]
                                  .map(
                                    (location) => DropdownMenuItem<String>(
                                      value: location,
                                      child: Text(
                                        location,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _filterDestination = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: query.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final docs = snapshot.data!.docs;
                          final rides = docs.map((doc) => Ride.fromFirestore(doc)).toList();

                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);

                          final futureRides = rides.where((r) {
                            final rideDay = DateTime(r.rideDate.year, r.rideDate.month, r.rideDate.day);
                            return !rideDay.isBefore(today);
                          }).toList()
                            ..sort((a, b) => a.rideDate.compareTo(b.rideDate));

                          if (futureRides.isEmpty) {
                            return AppEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No rides found',
                              subtitle: _filterDestination == allLocationsLabel
                                  ? 'There are no open rides right now.'
                                  : 'Try another destination or switch back to all locations.',
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: futureRides.length,
                            itemBuilder: (context, index) {
                              final ride = futureRides[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: StandardRideCard(
                                  ride: ride,
                                  onTap: () => showRideDetailsSheet(context, ride),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
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

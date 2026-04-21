import 'package:flutter/material.dart';
import 'package:unipool/data/ride_locations.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/providers/ride_repository_scope.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/widgets/ride_card.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

enum TimeFilter { any, morning, afternoon, evening, night }

class _FindRideScreenState extends State<FindRideScreen> {
  String _filterDestination = allLocationsLabel;
  TimeFilter _timeFilter = TimeFilter.any;

  int? _parseHour(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[:\s]'));
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        if (timeStr.toLowerCase().contains('pm') && hour < 12) hour += 12;
        if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;
        return hour;
      }
    } catch (_) {}
    return null;
  }

  bool _matchesTime(String? rideTime) {
    if (_timeFilter == TimeFilter.any) return true;
    if (rideTime == null || rideTime.isEmpty) return false;
    final hour = _parseHour(rideTime);
    if (hour == null) return false;

    switch (_timeFilter) {
      case TimeFilter.morning:
        return hour >= 6 && hour < 12; // 6 AM - 11:59 AM
      case TimeFilter.afternoon:
        return hour >= 12 && hour < 17; // 12 PM - 4:59 PM
      case TimeFilter.evening:
        return hour >= 17 && hour < 21; // 5 PM - 8:59 PM
      case TimeFilter.night:
        return hour >= 21 || hour < 6; // 9 PM - 5:59 AM
      default:
        return true;
    }
  }

  String _timeFilterLabel(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.any:
        return 'Any time';
      case TimeFilter.morning:
        return 'Morning';
      case TimeFilter.afternoon:
        return 'Afternoon';
      case TimeFilter.evening:
        return 'Evening';
      case TimeFilter.night:
        return 'Night';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideRepository = RideRepositoryScope.of(context);
    final destinationFilter = _filterDestination == allLocationsLabel
        ? null
        : _filterDestination;

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
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: TimeFilter.values.map((filter) {
                                  final isSelected = _timeFilter == filter;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(_timeFilterLabel(filter)),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _timeFilter = filter);
                                        }
                                      },
                                      selectedColor: AppColors.primary,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.ink,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Ride>>(
                        stream: rideRepository.watchSearchingRides(
                          destination: destinationFilter,
                        ),
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

                          final rides = snapshot.data!;

                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);

                          final futureRides =
                              rides.where((r) {
                                final rideDay = DateTime(
                                  r.rideDate.year,
                                  r.rideDate.month,
                                  r.rideDate.day,
                                );
                                if (rideDay.isBefore(today)) return false;
                                return _matchesTime(r.rideTime);
                              }).toList()..sort(
                                (a, b) => a.rideDate.compareTo(b.rideDate),
                              );

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
                                  onTap: () =>
                                      showRideDetailsSheet(context, ride),
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

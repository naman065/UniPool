import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipool/data/ride_locations.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/models/ride.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  String? _selectedSource;
  String? _selectedDestination;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _fareController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  Future<void> _submitRide() async {
    if (_selectedSource == null ||
        _selectedDestination == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _fareController.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        'Select route, date, time, and fare before posting.',
        isError: true,
      );
      return;
    }

    if (_selectedSource == _selectedDestination) {
      showAppSnackBar(
        context,
        'Source and destination should be different.',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userData.data() ?? <String, dynamic>{};
      final leaderName = (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : user.email?.split('@').first ?? 'Student';

      final newRide = Ride(
        id: '', // Will be assigned by Firestore
        source: _selectedSource!,
        destination: _selectedDestination!,
        rideDate: _selectedDate!,
        leaderId: user.uid,
        leaderName: leaderName,
        status: 'open',
        participants: [],
        rideTime: _selectedTime!.format(context),
        fare: _fareController.text.trim(),
      );

      final rideMap = newRide.toMap();
      rideMap['createdAt'] = Timestamp.now();

      await FirebaseFirestore.instance.collection('rides').add(rideMap);

      if (mounted) {
        Navigator.of(context).pop();
        showAppSnackBar(context, 'Ride posted successfully.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to post ride: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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
                title: 'Create ride',
                subtitle: 'Set the route and date.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Leader mode',
                  icon: Icons.local_taxi_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: 'Trip details',
                        subtitle: 'Choose the route for this ride.',
                      ),
                      const SizedBox(height: 18),
                      AppSurfaceCard(
                        child: Column(
                          children: [
                            _buildDropdownField(
                              value: _selectedSource,
                              hint: 'From',
                              icon: Icons.my_location_rounded,
                              iconColor: AppColors.primary,
                              onChanged: (value) =>
                                  setState(() => _selectedSource = value),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: const [
                                  SizedBox(width: 14),
                                  Icon(
                                    Icons.south_rounded,
                                    color: AppColors.muted,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            _buildDropdownField(
                              value: _selectedDestination,
                              hint: 'To',
                              icon: Icons.place_rounded,
                              iconColor: AppColors.accent,
                              onChanged: (value) =>
                                  setState(() => _selectedDestination = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppSurfaceCard(
                        child: InkWell(
                          onTap: _presentDatePicker,
                          borderRadius: BorderRadius.circular(26),
                          child: Row(
                            children: [
                              const AppIconBadge(
                                icon: Icons.calendar_month_rounded,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ride date',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedDate == null
                                          ? 'Choose the travel day'
                                          : DateFormat(
                                              'EEEE, d MMM yyyy',
                                            ).format(_selectedDate!),
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.muted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppSurfaceCard(
                        child: InkWell(
                          onTap: _presentTimePicker,
                          borderRadius: BorderRadius.circular(26),
                          child: Row(
                            children: [
                              const AppIconBadge(
                                icon: Icons.schedule_rounded,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Time of departure',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedTime == null
                                          ? 'Approximate time'
                                          : _selectedTime!.format(context),
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.muted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppSurfaceCard(
                        child: TextField(
                          controller: _fareController,
                          maxLength: 40,
                          decoration: const InputDecoration(
                            counterText: '',
                            labelText: 'Fare estimate (e.g., ₹ 150 or by meter)',
                            prefixIcon: Icon(
                              Icons.payments_rounded,
                              color: AppColors.primary,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppSurfaceCard(
                        color: AppColors.surfaceSoft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppSectionHeader(
                              title: 'Preview',
                              subtitle: 'Check the ride before posting.',
                            ),
                            const SizedBox(height: 18),
                            _PreviewRow(
                              label: 'Route',
                              value:
                                  _selectedSource == null ||
                                      _selectedDestination == null
                                  ? 'Select both ends of the trip'
                                  : '$_selectedSource to $_selectedDestination',
                            ),
                            const SizedBox(height: 12),
                            _PreviewRow(
                              label: 'Date',
                              value: _selectedDate == null
                                  ? 'Choose a day for the ride'
                                  : DateFormat(
                                      'd MMM yyyy',
                                    ).format(_selectedDate!),
                            ),
                            const SizedBox(height: 12),
                            _PreviewRow(
                              label: 'Time',
                              value: _selectedTime == null
                                  ? 'Not set'
                                  : _selectedTime!.format(context),
                            ),
                            const SizedBox(height: 12),
                            _PreviewRow(
                              label: 'Fare',
                              value: _fareController.text.trim().isEmpty
                                  ? 'Not set'
                                  : _fareController.text.trim(),
                            ),
                            const SizedBox(height: 12),
                            const _PreviewRow(
                              label: 'Status',
                              value: 'Open for poolers to discover',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: AppPrimaryButton(
                          label: 'Post ride request',
                          icon: Icons.arrow_upward_rounded,
                          isLoading: _submitting,
                          onPressed: _submitRide,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: iconColor),
      ),
      items: rideLocations
          .map(
            (location) => DropdownMenuItem<String>(
              value: location,
              child: Text(location, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
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

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

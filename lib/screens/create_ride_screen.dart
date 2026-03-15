import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  // 1. New Variables for Dropdowns
  final List<String> _locations = [
    // Original Campus Locations
    'Hall 1',
    'Hall 2',
    'Hall 3',
    'Hall 4',
    'Hall 12',
    'Hall 13',
    'Academic Area',
    'Library',
    'Main Gate',
    'Health Centre',
    
    
    // Kanpur Metro Stations (Cleaned)
    'IIT Kanpur',
    'Kalyanpur Metro',
    'SPM Hospital',
    'Vishwavidyalaya',
    'Gurudev Chauraha',
    'Geeta Nagar',
    'Rawatpur',
    'GSVM Medical College',
    'Moti Jheel',
    'Chunniganj',
    'Naveen Market',
    'Bada Chauraha',
    'Nayaganj',
    'Kanpur Central Railway Station',
    'Lucknow Airport',
    'Z Square Mall',
  ];

  String? _selectedSource;
  String? _selectedDestination;
  DateTime? _selectedDate;
  bool _submitting = false;

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submitRide() async {
    // 2. Updated Validation logic
    if (_selectedSource == null ||
        _selectedDestination == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select source, destination, and date!')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      await FirebaseFirestore.instance.collection('rides').add({
        'source': _selectedSource,
        'destination': _selectedDestination,
        'rideDate': _selectedDate!.toIso8601String(),
        'leaderId': user.uid,
        'leaderName': userData.data()?['name'] ?? 'Student',
        'status': 'open',
        'participants': [],
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post ride: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create a Ride',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Where are you going?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              "Select your campus route and timing",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            
            // 3. Updated UI with Dropdowns
            _buildCard(
              child: Column(
                children: [
                  _buildDropdownField(
                    value: _selectedSource,
                    hint: 'From (Source)',
                    icon: Icons.my_location_rounded,
                    iconColor: const Color(0xFF6C63FF),
                    onChanged: (val) => setState(() => _selectedSource = val),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: List.generate(
                        3,
                        (i) => Container(
                          width: 2,
                          height: 6,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  _buildDropdownField(
                    value: _selectedDestination,
                    hint: 'To (Destination)',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFFB06AB3),
                    onChanged: (val) => setState(() => _selectedDestination = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildCard(
              child: ListTile(
                onTap: _presentDatePicker,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF6C63FF), size: 20),
                ),
                title: Text(
                  _selectedDate == null ? 'Select Date' : DateFormat('dd MMMM, yyyy').format(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey[400] : const Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post Ride Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  // 4. New Dropdown Widget method
  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(Icons.expand_more_rounded, color: Colors.grey),
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.8),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
      ),
      items: _locations.map((loc) {
        return DropdownMenuItem(
          value: loc,
          child: Text(loc),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
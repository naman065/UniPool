import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipool/screens/chat_screen.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  // Use the exact same locations as your CreateRideScreen
  final List<String> _locations = [
    'All Locations',
    'Hall 1', 'Hall 2', 'Hall 3', 'Hall 4', 'Hall 12', 'Hall 13',
    'Academic Area', 'Library', 'Main Gate', 'Health Centre', 'Shopping Centre',
    'IIT Kanpur', 'Kalyanpur Metro', 'SPM Hospital', 'Vishwavidyalaya',
    'Gurudev Chauraha', 'Geeta Nagar', 'Rawatpur', 'GSVM Medical College',
    'Moti Jheel', 'Chunniganj', 'Naveen Market', 'Bada Chauraha', 'Nayaganj',
    'Kanpur Central Railway Station', 'Lucknow Airport',
  ];

  String _filterDestination = 'All Locations';

  @override
  Widget build(BuildContext context) {
    // Build the query based on selection [cite: 67]
    Query query = FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'open');

    if (_filterDestination != 'All Locations') {
      query = query.where('destination', isEqualTo: _filterDestination);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Available Rides', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // --- NEW FILTER BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterDestination,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
                      style: const TextStyle(color: Color(0xFF0F0C29), fontWeight: FontWeight.w600, fontSize: 14),
                      items: _locations.map((loc) {
                        return DropdownMenuItem(value: loc, child: Text(loc));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _filterDestination = val!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // --- RIDES LIST (Moved inside Expanded) ---
          Expanded(
            child: StreamBuilder(
              stream: query.snapshots(),
              builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF6C63FF)),
                        ),
                        const SizedBox(height: 18),
                        const Text('No rides found', 
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F0C29))),
                        const SizedBox(height: 6),
                        Text('Try changing your destination filter!', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  );
                }

                final rideDocs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rideDocs.length,
                  itemBuilder: (ctx, index) {
                    var ride = rideDocs[index];
                    return _RideCard(
                      ride: ride,
                      onTap: () => _showRideDetails(context, ride),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Keeping your existing detail dialog and helper methods exactly as they were [cite: 76, 106]
  void _showRideDetails(BuildContext context, DocumentSnapshot ride) async {
    final leaderData = await FirebaseFirestore.instance
        .collection('users')
        .doc(ride['leaderId'])
        .get();
    final ridesCount = (leaderData.exists && (leaderData.data() as Map).containsKey('ridesCompleted'))
        ? leaderData['ridesCompleted']
        : 0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFFB06AB3)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Ride Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F0C29))),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.my_location_rounded, 'From', ride['source'], const Color(0xFF6C63FF)),
              const SizedBox(height: 12),
              _detailRow(Icons.location_on_rounded, 'To', ride['destination'], const Color(0xFFB06AB3)),
              const SizedBox(height: 12),
              _detailRow(Icons.calendar_today_rounded, 'Date', ride['rideDate'].toString().split('T')[0], const Color(0xFF00B4DB)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF302B63),
                      child: Text(
                        ride['leaderName'].toString().isNotEmpty ? ride['leaderName'].toString()[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ride['leaderName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F0C29))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 14),
                            const SizedBox(width: 4),
                            Text('$ridesCount rides completed', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF302B63), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFFB06AB3)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => ChatScreen(
                                rideId: ride.id,
                                rideDestination: ride['destination'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                        label: const Text('Join & Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ],
        ),
      ],
    );
  }
}

class _RideCard extends StatelessWidget {
  final DocumentSnapshot ride;
  final VoidCallback onTap;

  const _RideCard({required this.ride, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFFB06AB3)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ride['source']} → ${ride['destination']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F0C29)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(ride['leaderName'], style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 10),
                        Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(ride['rideDate'].toString().split('T')[0], style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Open', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
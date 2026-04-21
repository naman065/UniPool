import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipool/models/notification.dart';
import 'package:unipool/screens/ride_requests_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markNotificationAsRead(
    DocumentReference<Object?> reference,
  ) async {
    await reference.update({'isRead': true});
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _openNotification(
    BuildContext context,
    DocumentSnapshot doc,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await _markNotificationAsRead(doc.reference);
    }

    if (!context.mounted) {
      return;
    }

    if (notification.isJoinRequest && notification.rideId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RideRequestsScreen(rideId: notification.rideId!),
        ),
      );
    }
  }

  @override
  void deactivate() {
    // When leaving the screen, actively mark these as read so the badge disappears
    _markAllAsRead();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'Notifications',
                subtitle: 'Updates on your upcoming rides',
                leading: Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
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
                ),
                badge: const AppPill(
                  label: 'History',
                  icon: Icons.history_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('notifications')
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: AppEmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'No notifications',
                          subtitle: 'You are all caught up!',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final notif = AppNotification.fromFirestore(doc);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _openNotification(context, doc, notif),
                              borderRadius: BorderRadius.circular(26),
                              child: AppSurfaceCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppIconBadge(
                                      icon: notif.isJoinRequest
                                          ? Icons.person_add_alt_rounded
                                          : Icons.info_outline_rounded,
                                      color: notif.isRead
                                          ? AppColors.muted
                                          : notif.isJoinRequest
                                          ? AppColors.secondary
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: TextStyle(
                                                    color: AppColors.ink,
                                                    fontWeight: notif.isRead
                                                        ? FontWeight.w700
                                                        : FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (notif.isJoinRequest)
                                                const AppPill(
                                                  label: 'Open',
                                                  icon: Icons
                                                      .arrow_forward_rounded,
                                                  foregroundColor:
                                                      AppColors.secondary,
                                                  backgroundColor:
                                                      Color(0xFF163A36),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notif.body,
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              height: 1.4,
                                              fontWeight: notif.isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            DateFormat(
                                              'MMM d, h:mm a',
                                            ).format(notif.createdAt),
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

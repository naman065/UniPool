import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipool/models/ride.dart';
import 'package:unipool/providers/ride_repository_scope.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.rideId,
    required this.rideDestination,
  });

  final String rideId;
  final String rideDestination;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final rideDoc = await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .get();

    if (!rideDoc.exists) {
      if (mounted) {
        showAppSnackBar(context, 'Ride not found.');
      }
      return;
    }

    final ride = Ride.fromFirestore(rideDoc);
    if (!ride.includesUser(user.uid)) {
      if (mounted) {
        showAppSnackBar(context, 'Only approved riders can use the ride chat.');
      }
      return;
    }

    await FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .collection('messages')
        .add({
          'text': message,
          'createdAt': Timestamp.now(),
          'senderId': user.uid,
          'senderEmail': user.email,
        });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: widget.rideDestination,
                subtitle:
                    'Keep pickup timing, confirmations, and small updates in one focused thread.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Ride chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rides')
                      .doc(widget.rideId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.forum_outlined,
                        title: 'No messages yet',
                        subtitle:
                            'Start the conversation with pickup details or a quick hello.',
                      );
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msgData = messages[index];
                        final isMe = msgData['senderId'] == currentUser.uid;
                        final senderName = isMe
                            ? 'You'
                            : msgData['senderEmail']
                                  .toString()
                                  .split('@')
                                  .first;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.76,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? AppColors.accentGradient
                                      : null,
                                  color: isMe ? null : AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(22),
                                    topRight: const Radius.circular(22),
                                    bottomLeft: Radius.circular(isMe ? 22 : 8),
                                    bottomRight: Radius.circular(isMe ? 8 : 22),
                                  ),
                                  border: isMe
                                      ? null
                                      : Border.all(color: AppColors.line),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msgData['text'],
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.ink,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$senderName · ${_formatTime(msgData['createdAt'])}',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white.withValues(
                                                alpha: 0.78,
                                              )
                                            : AppColors.muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
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
              StreamBuilder<Ride?>(
                stream: RideRepositoryScope.of(
                  context,
                ).watchRide(widget.rideId),
                builder: (context, rideSnapshot) {
                  final ride = rideSnapshot.data;
                  final canChat = ride?.includesUser(currentUser.uid) ?? false;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: AppSurfaceCard(
                      padding: const EdgeInsets.all(12),
                      radius: 28,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: canChat,
                              minLines: 1,
                              maxLines: 4,
                              onSubmitted: canChat
                                  ? (_) => _sendMessage()
                                  : null,
                              decoration: InputDecoration(
                                hintText: canChat
                                    ? 'Type a message'
                                    : 'Request approval before chatting',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: canChat
                                  ? AppColors.accentGradient
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF404A5D),
                                        Color(0xFF404A5D),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: canChat ? _sendMessage : null,
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('h:mm a').format(timestamp.toDate());
    }
    return '';
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

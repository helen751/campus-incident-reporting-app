import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;

  int unreadCount = 0;
  bool firstLoad = true;

  @override
  void initState() {
    super.initState();
    listenForNotifications();
  }

  // listening for new unread notifications
  void listenForNotifications() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      final newCount = snapshot.docs.length;

      // playing a sound when a new notification arrives
      if (!firstLoad && newCount > unreadCount) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
      }

      if (mounted) {
        setState(() {
          unreadCount = newCount;
          firstLoad = false;
        });
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: widget.onPressed,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF12355B),
            size: 28,
          ),
        ),

        if (unreadCount > 0)
          Positioned(
            right: 3,
            top: 2,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 19,
                minHeight: 19,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
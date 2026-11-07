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
  State<NotificationBell> createState() =>
      _NotificationBellState();
}

class _NotificationBellState
    extends State<NotificationBell> {
  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);

  int previousCount = 0;
  bool countLoaded = false;
  bool markingAsRead = false;

  // checking whether a new notification arrived
  void checkForNewNotification(int currentCount) {
    if (!countLoaded) {
      previousCount = currentCount;
      countLoaded = true;
      return;
    }

    final notificationAdded =
        currentCount > previousCount;

    previousCount = currentCount;

    if (!notificationAdded) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // playing the notification sound
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();

      final messenger =
      ScaffoldMessenger.maybeOf(context);

      messenger?.hideCurrentSnackBar();

      messenger?.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You have a new CampusFire update.',
                ),
              ),
            ],
          ),
          backgroundColor: navy,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    });
  }

  // marking reports and notifications as read
  Future<void> markEverythingAsRead({
    required List<
        DocumentReference<Map<String, dynamic>>>
    incidents,
    required List<
        DocumentReference<Map<String, dynamic>>>
    notifications,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (incidents.isEmpty && notifications.isEmpty) {
      widget.onPressed();
      return;
    }

    setState(() {
      markingAsRead = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // marking new incident reports as seen
      for (final incident in incidents) {
        batch.update(incident, {
          'readBy': FieldValue.arrayUnion(
            [user.uid],
          ),
        });
      }

      // marking personal status notifications as read
      for (final notification in notifications) {
        batch.update(notification, {
          'isRead': true,
        });
      }

      await batch.commit();
    } catch (error) {
      debugPrint(
        'Could not mark notifications as read: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          markingAsRead = false;
        });
      }

      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox();
    }

    // listening for new incident reports
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .snapshots(),
      builder: (context, incidentSnapshot) {
        final incidentDocuments =
            incidentSnapshot.data?.docs ?? [];

        final unreadIncidents =
        incidentDocuments.where((incident) {
          final data = incident.data();

          final reporterId =
              data['reportedBy']?.toString() ?? '';

          final readBy = List<String>.from(
            data['readBy'] ?? [],
          );

          // not notifying users about their own reports
          return reporterId != user.uid &&
              !readBy.contains(user.uid);
        }).toList();

        // listening for personal status notifications
        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where(
            'userId',
            isEqualTo: user.uid,
          )
              .snapshots(),
          builder: (context, notificationSnapshot) {
            final notificationDocuments =
                notificationSnapshot.data?.docs ?? [];

            final unreadNotifications =
            notificationDocuments.where((notification) {
              return notification.data()['isRead'] !=
                  true;
            }).toList();

            final unreadCount =
                unreadIncidents.length +
                    unreadNotifications.length;

            checkForNewNotification(unreadCount);

            return IconButton(
              onPressed: markingAsRead
                  ? null
                  : () {
                markEverythingAsRead(
                  incidents: unreadIncidents
                      .map(
                        (incident) =>
                    incident.reference,
                  )
                      .toList(),
                  notifications:
                  unreadNotifications
                      .map(
                        (notification) =>
                    notification.reference,
                  )
                      .toList(),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  markingAsRead
                      ? const SizedBox(
                    width: 26,
                    height: 26,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: navy,
                    ),
                  )
                      : const Icon(
                    Icons
                        .notifications_none_rounded,
                    color: navy,
                    size: 28,
                  ),

                  if (unreadCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 21,
                          minHeight: 21,
                        ),
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: coral,
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99
                              ? '99+'
                              : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
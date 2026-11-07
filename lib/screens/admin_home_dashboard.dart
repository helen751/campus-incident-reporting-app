import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHomeDashboard extends StatefulWidget {
  const AdminHomeDashboard({
    super.key,
    required this.onReviewPressed,
  });

  final VoidCallback onReviewPressed;

  @override
  State<AdminHomeDashboard> createState() =>
      _AdminHomeDashboardState();
}

class _AdminHomeDashboardState
    extends State<AdminHomeDashboard>
    with TickerProviderStateMixin {
  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color blue = Color(0xFF3787E5);
  static const Color background = Color(0xFFF4F7FB);

  late final AnimationController entranceController;
  late final AnimationController personController;

  late final Animation<double> pageOpacity;
  late final Animation<Offset> pagePosition;
  late final Animation<double> personMovement;

  @override
  void initState() {
    super.initState();

    // controlling the dashboard entrance
    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    pageOpacity = CurvedAnimation(
      parent: entranceController,
      curve: Curves.easeOut,
    );

    pagePosition = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // moving the admin image gently
    personController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    personMovement = Tween<double>(
      begin: -4,
      end: 5,
    ).animate(
      CurvedAnimation(
        parent: personController,
        curve: Curves.easeInOut,
      ),
    );

    entranceController.forward();
    personController.repeat(reverse: true);
  }

  @override
  void dispose() {
    entranceController.dispose();
    personController.dispose();
    super.dispose();
  }

  // returning the status color
  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return blue;

      case 'in progress':
        return Colors.orange;

      case 'resolved':
        return mint;

      default:
        return coral;
    }
  }

  // returning the status icon
  IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.verified_rounded;

      case 'in progress':
        return Icons.construction_rounded;

      case 'resolved':
        return Icons.task_alt_rounded;

      default:
        return Icons.pending_actions_rounded;
    }
  }

  // formatting the Firestore date
  String formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Just now';
    }

    final date = value.toDate();
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // returning the incident date for sorting
  DateTime incidentDate(
      Map<String, dynamic> incident,
      ) {
    final value = incident['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    final firstName =
    displayName != null && displayName.isNotEmpty
        ? displayName.split(' ').first
        : 'Admin';

    return Container(
      color: background,
      child: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('incidents')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: coral,
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          final incidents = documents.map((document) {
            return <String, dynamic>{
              ...document.data(),
              'id': document.id,
            };
          }).toList();

          incidents.sort(
                (first, second) {
              return incidentDate(second).compareTo(
                incidentDate(first),
              );
            },
          );

          final submittedCount =
              incidents.where((incident) {
                return incident['status']
                    ?.toString()
                    .toLowerCase() ==
                    'submitted';
              }).length;

          final verifiedCount =
              incidents.where((incident) {
                return incident['status']
                    ?.toString()
                    .toLowerCase() ==
                    'verified';
              }).length;

          final progressCount =
              incidents.where((incident) {
                return incident['status']
                    ?.toString()
                    .toLowerCase() ==
                    'in progress';
              }).length;

          final resolvedCount =
              incidents.where((incident) {
                return incident['status']
                    ?.toString()
                    .toLowerCase() ==
                    'resolved';
              }).length;

          final activeIncidents =
          incidents.where((incident) {
            return incident['status']
                ?.toString()
                .toLowerCase() !=
                'resolved';
          }).toList();

          final resolutionProgress =
          incidents.isEmpty
              ? 0.0
              : resolvedCount / incidents.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              35,
            ),
            child: FadeTransition(
              opacity: pageOpacity,
              child: SlideTransition(
                position: pagePosition,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $firstName',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Here is what needs your attention today.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // showing the main admin banner
                    AdminReviewHero(
                      submittedCount: submittedCount,
                      personMovement: personMovement,
                      personController: personController,
                      onReviewPressed:
                      widget.onReviewPressed,
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Incident overview',
                      style: TextStyle(
                        color: navy,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // showing the status totals
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            title: 'Submitted',
                            number: submittedCount,
                            icon:
                            Icons.pending_actions_rounded,
                            color: coral,
                            delay: 0,
                          ),
                        ),

                        const SizedBox(width: 11),

                        Expanded(
                          child: AdminStatCard(
                            title: 'Verified',
                            number: verifiedCount,
                            icon: Icons.verified_rounded,
                            color: blue,
                            delay: 100,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 11),

                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            title: 'In progress',
                            number: progressCount,
                            icon:
                            Icons.construction_rounded,
                            color: Colors.orange,
                            delay: 200,
                          ),
                        ),

                        const SizedBox(width: 11),

                        Expanded(
                          child: AdminStatCard(
                            title: 'Resolved',
                            number: resolvedCount,
                            icon: Icons.task_alt_rounded,
                            color: mint,
                            delay: 300,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // showing the resolution progress
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(22),
                        border: Border.all(
                          color:
                          const Color(0xFFE1E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  color:
                                  mint.withOpacity(0.12),
                                  borderRadius:
                                  BorderRadius.circular(
                                    14,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.insights_rounded,
                                  color: mint,
                                ),
                              ),

                              const SizedBox(width: 12),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Resolution progress',
                                      style: TextStyle(
                                        color: navy,
                                        fontSize: 15,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Resolved incidents compared to all reports',
                                      style: TextStyle(
                                        color:
                                        Colors.black45,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                '${(resolutionProgress * 100).round()}%',
                                style: const TextStyle(
                                  color: mint,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 17),

                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(10),
                            child:
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: resolutionProgress,
                              ),
                              duration: const Duration(
                                milliseconds: 900,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (
                                  context,
                                  value,
                                  child,
                                  ) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 9,
                                  backgroundColor:
                                  mint.withOpacity(0.12),
                                  valueColor:
                                  const AlwaysStoppedAnimation(
                                    mint,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 27),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Needs review',
                            style: TextStyle(
                              color: navy,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed:
                          widget.onReviewPressed,
                          child: const Text(
                            'View all',
                            style: TextStyle(
                              color: coral,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (activeIncidents.isEmpty)
                      const AdminEmptyQueue()
                    else
                      Column(
                        children: List.generate(
                          activeIncidents.take(3).length,
                              (index) {
                            final incident =
                            activeIncidents[index];

                            final status =
                                incident['status']
                                    ?.toString() ??
                                    'Submitted';

                            return TweenAnimationBuilder<
                                double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: 1,
                              ),
                              duration: Duration(
                                milliseconds:
                                350 + (index * 100),
                              ),
                              curve: Curves.easeOutBack,
                              builder: (
                                  context,
                                  animation,
                                  child,
                                  ) {
                                return Opacity(
                                  opacity: animation.clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  child:
                                  Transform.translate(
                                    offset: Offset(
                                      35 *
                                          (1 - animation),
                                      0,
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              child: Padding(
                                padding:
                                const EdgeInsets.only(
                                  bottom: 13,
                                ),
                                child:
                                AdminReviewIncidentCard(
                                  incident: incident,
                                  date: formatDate(
                                    incident[
                                    'updatedAt'] ??
                                        incident[
                                        'createdAt'],
                                  ),
                                  color:
                                  statusColor(status),
                                  icon:
                                  statusIcon(status),
                                  onPressed: widget
                                      .onReviewPressed,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),

                    // showing emergency information
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor:
                            Colors.white12,
                            child: Icon(
                              Icons
                                  .admin_panel_settings_outlined,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Administrator responsibility',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Verify reports carefully and update their status as action is taken.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }
}

class AdminReviewHero extends StatelessWidget {
  const AdminReviewHero({
    super.key,
    required this.submittedCount,
    required this.personMovement,
    required this.personController,
    required this.onReviewPressed,
  });

  final int submittedCount;
  final Animation<double> personMovement;
  final AnimationController personController;
  final VoidCallback onReviewPressed;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 285,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            navy,
            Color(0xFF1D5685),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: coral.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              right: 70,
              bottom: -75,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: mint.withOpacity(0.11),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: 21,
              top: 21,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons
                          .admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'STAFF REVIEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 21,
              top: 75,
              right: 145,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review Reports.\nKeep campus safe.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    submittedCount == 0
                        ? 'There are no new reports waiting for review.'
                        : '$submittedCount new ${submittedCount == 1 ? 'report needs' : 'reports need'} your attention.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 21,
              bottom: 22,
              child: ElevatedButton.icon(
                onPressed: onReviewPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(
                  Icons.fact_check_outlined,
                  size: 19,
                ),
                label: const Text(
                  'Review reports',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // showing the admin image
            Positioned(
              right: -8,
              bottom: -4,
              child: AnimatedBuilder(
                animation: personController,
                child: Image.asset(
                  'assets/images/admin_person.png',
                  width: 190,
                  height: 235,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return Container(
                      width: 135,
                      height: 165,
                      margin: const EdgeInsets.only(
                        right: 20,
                        bottom: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons
                            .admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 65,
                      ),
                    );
                  },
                ),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      personMovement.value,
                    ),
                    child: child,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.number,
    required this.icon,
    required this.color,
    required this.delay,
  });

  final String title;
  final int number;
  final IconData icon;
  final Color color;
  final int delay;

  static const Color navy = Color(0xFF12355B);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ),
      duration: Duration(
        milliseconds: 450 + delay,
      ),
      curve: Curves.easeOutBack,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + (0.15 * animation),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: navy.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      color: color,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminReviewIncidentCard extends StatelessWidget {
  const AdminReviewIncidentCard({
    super.key,
    required this.incident,
    required this.date,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final Map<String, dynamic> incident;
  final String date;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  static const Color navy = Color(0xFF12355B);
  static const Color background = Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    final title =
        incident['title']?.toString() ??
            'Campus incident';

    final location =
        incident['location']?.toString() ??
            'ALU Campus';

    final status =
        incident['status']?.toString() ??
            'Submitted';

    final reporter =
        incident['reporterName']?.toString() ??
            'CampusFire User';

    final imageUrl =
        incident['imageUrl']?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFFE1E8F0),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  width: 68,
                  height: 74,
                  fit: BoxFit.cover,
                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return AdminStatusPlaceholder(
                      color: color,
                      icon: icon,
                    );
                  },
                )
                    : AdminStatusPlaceholder(
                  color: color,
                  icon: icon,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: navy,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.11),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reporter,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminStatusPlaceholder extends StatelessWidget {
  const AdminStatusPlaceholder({
    super.key,
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 74,
      color: color.withOpacity(0.10),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }
}

class AdminEmptyQueue extends StatelessWidget {
  const AdminEmptyQueue({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE1E8F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: Color(0xFF2EC4B6),
            size: 45,
          ),
          SizedBox(height: 10),
          Text(
            'All caught up',
            style: TextStyle(
              color: Color(0xFF12355B),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'There are no active incidents waiting for review.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
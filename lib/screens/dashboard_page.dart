import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'updates_page.dart';
import 'report_page.dart';
import 'your_fires_page.dart';
import 'profile_page.dart';
import '../widgets/notification_bell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_dashboard.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.isAdmin = false,
  });

  final bool isAdmin;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  // changing the selected page
  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      widget.isAdmin
          ? AdminHomeDashboard(
        onReviewPressed: () => changePage(1),
      )
          : HomeDashboard(
        onReportPressed: () => changePage(2),
        onUpdatesPressed: () => changePage(1),
      ),
      const UpdatesPage(),
      const ReportPage(),
      const YourFiresPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // showing the logo and top icons
            DashboardTopBar(
              onNotificationPressed: () => changePage(1),
              onProfilePressed: () => changePage(4),
            ),

            // showing the selected page
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      ),

      // showing the bottom navigation
      bottomNavigationBar: DashboardNavigation(
        selectedIndex: selectedIndex,
        onSelected: changePage,
      ),
    );
  }
}

class DashboardTopBar extends StatelessWidget {
  final VoidCallback onNotificationPressed;
  final VoidCallback onProfilePressed;

  const DashboardTopBar({
    super.key,
    required this.onNotificationPressed,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      color: Colors.white,
      child: Row(
        children: [
          // showing the CampusFire logo
          Image.asset(
            'assets/images/campusfire_logo.png',
            width: 105,
            height: 55,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.local_fire_department,
                color: _DashboardPageState.coral,
                size: 42,
              );
            },
          ),

          const Spacer(),

          // opening the updates page
          NotificationBell(
            onPressed: onNotificationPressed,
          ),

          const SizedBox(width: 10),

          // opening the profile page
          GestureDetector(
            onTap: onProfilePressed,
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: _DashboardPageState.navy,
              child: Icon(
                Icons.person_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LatestIncidentCard extends StatelessWidget {
  const LatestIncidentCard({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFF3787E5);

      case 'in progress':
        return Colors.orange;

      case 'resolved':
        return mint;

      default:
        return coral;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            height: 145,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5EAF0),
              ),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: coral,
              strokeWidth: 2.5,
            ),
          );
        }

        if (snapshot.hasError) {
          return _LatestUpdateMessage(
            icon: Icons.cloud_off_outlined,
            iconColor: Colors.red,
            title: 'Could not load the latest update',
            subtitle: 'Check your connection and try again.',
            onPressed: onPressed,
          );
        }

        final documents = snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return _LatestUpdateMessage(
            icon: Icons.check_circle_outline,
            iconColor: mint,
            title: 'Campus is currently safe',
            subtitle: 'There are no incident reports yet.',
            onPressed: onPressed,
          );
        }

        final incident = documents.first.data();

        final title =
            incident['title']?.toString() ??
                'Campus incident';

        final status =
            incident['status']?.toString() ??
                'Submitted';

        final location =
            incident['location']?.toString() ??
                'ALU Campus';

        final imageUrl =
            incident['imageUrl']?.toString() ?? '';

        final color = statusColor(status);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: color.withOpacity(0.20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: navy.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(15),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (
                              context,
                              error,
                              stackTrace,
                              ) {
                            return _LatestStatusIcon(
                              color: color,
                              icon: statusIcon(status),
                            );
                          },
                        )
                            : _LatestStatusIcon(
                          color: color,
                          icon: statusIcon(status),
                        ),
                      ),

                      const SizedBox(width: 13),

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
                                      fontSize: 15,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    color.withOpacity(0.11),
                                    borderRadius:
                                    BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        statusIcon(status),
                                        color: color,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 9,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.black38,
                                  size: 15,
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
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatDate(
                                    incident['updatedAt'] ??
                                        incident['createdAt'],
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 5),

                      const Icon(
                        Icons.chevron_right,
                        color: Colors.black38,
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // showing the current progress
                  DashboardIncidentProgress(
                    currentStatus: status,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardIncidentProgress extends StatelessWidget {
  const DashboardIncidentProgress({
    super.key,
    required this.currentStatus,
  });

  final String currentStatus;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);

  static const List<String> stages = [
    'Submitted',
    'Verified',
    'In Progress',
    'Resolved',
  ];

  int get currentIndex {
    final index = stages.indexWhere(
          (stage) =>
      stage.toLowerCase() ==
          currentStatus.toLowerCase(),
    );

    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        stages.length,
            (index) {
          final completed = index <= currentIndex;
          final isLast = index == stages.length - 1;

          return Expanded(
            flex: isLast ? 0 : 1,
            child: Row(
              children: [
                AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 400),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color:
                    completed ? coral : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed
                          ? coral
                          : const Color(0xFFD4DEE8),
                      width: 2,
                    ),
                  ),
                  child: completed
                      ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 13,
                  )
                      : null,
                ),

                if (!isLast)
                  Expanded(
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 400),
                      height: 3,
                      color: index < currentIndex
                          ? coral
                          : const Color(0xFFD4DEE8),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LatestStatusIcon extends StatelessWidget {
  const _LatestStatusIcon({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: color.withOpacity(0.10),
      child: Icon(
        icon,
        color: color,
        size: 30,
      ),
    );
  }
}

class _LatestUpdateMessage extends StatelessWidget {
  const _LatestUpdateMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5EAF0),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                iconColor.withOpacity(0.10),
                child: Icon(
                  icon,
                  color: iconColor,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF12355B),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  final VoidCallback onReportPressed;
  final VoidCallback onUpdatesPressed;

  const HomeDashboard({
    super.key,
    required this.onReportPressed,
    required this.onUpdatesPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName?.trim();

    final firstName = displayName != null && displayName.isNotEmpty
        ? displayName.split(' ').first
        : 'there';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // greeting the current user
          Text(
            'Hello, $firstName 👋',
            style: const TextStyle(
              color: _DashboardPageState.navy,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Help us keep the ALU campus safe.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          // showing the main campus banner
          CampusHero(
            onReportPressed: onReportPressed,
          ),

          const SizedBox(height: 26),

          const Text(
            'Quick access',
            style: TextStyle(
              color: _DashboardPageState.navy,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          // showing the quick navigation cards
          Row(
            children: [
              Expanded(
                child: QuickAccessCard(
                  title: 'Report a fire',
                  subtitle: 'Send a new report',
                  icon: Icons.add_alert_outlined,
                  color: _DashboardPageState.coral,
                  onPressed: onReportPressed,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: QuickAccessCard(
                  title: 'Campus updates',
                  subtitle: 'View recent alerts',
                  icon: Icons.campaign_outlined,
                  color: _DashboardPageState.mint,
                  onPressed: onUpdatesPressed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Latest update',
                  style: TextStyle(
                    color: _DashboardPageState.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              TextButton(
                onPressed: onUpdatesPressed,
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: _DashboardPageState.coral,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // showing the latest incident from Firestore
          LatestIncidentCard(
            onPressed: onUpdatesPressed,
          ),

          const SizedBox(height: 22),

          // showing emergency information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _DashboardPageState.navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white12,
                  child: Icon(
                    Icons.local_phone_outlined,
                    color: Colors.white,
                  ),
                ),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency assistance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Call 912 immediately if anyone is in danger.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
    );
  }
}

class CampusHero extends StatefulWidget {
  final VoidCallback onReportPressed;

  const CampusHero({
    super.key,
    required this.onReportPressed,
  });

  @override
  State<CampusHero> createState() => _CampusHeroState();
}

class _CampusHeroState extends State<CampusHero>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late AnimationController personFloatController;

  late Animation<double> textFade;
  late Animation<double> personFloat;
  late Animation<Offset> personSlide;

  @override
  void initState() {
    super.initState();

    // controlling the hero animations
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    // fading the hero text into the screen
    textFade = CurvedAnimation(
      parent: animationController,
      curve: const Interval(
        0.0,
        0.65,
        curve: Curves.easeIn,
      ),
    );

    // sliding the person into the screen
    personSlide = Tween<Offset>(
      begin: const Offset(0.65, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(
          0.15,
          1.0,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    // controlling the person's floating movement
    personFloatController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

// moving the person gently up and down
    personFloat = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(
      CurvedAnimation(
        parent: personFloatController,
        curve: Curves.easeInOut,
      ),
    );

// starting the floating movement after the entrance
    animationController.forward().then((_) {
      if (mounted) {
        personFloatController.repeat(reverse: true);
      }
    });

  }

  @override
  void dispose() {
    animationController.dispose();
    personFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // showing the ALU campus
            Positioned.fill(
              child: Image.asset(
                'assets/images/alu_campus.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _DashboardPageState.navy,
                  );
                },
              ),
            ),

            // adding the dark image layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _DashboardPageState.navy
                          .withValues(alpha: 0.98),
                      _DashboardPageState.navy
                          .withValues(alpha: 0.78),
                      _DashboardPageState.navy
                          .withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),

            // showing the campus safety label
            Positioned(
              top: 24,
              left: 24,
              child: FadeTransition(
                opacity: textFade,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _DashboardPageState.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.safety_check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ALU CAMPUS Reporting',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // fading the main safety message
            Positioned(
              top: 78,
              left: 24,
              right: 145,
              child: FadeTransition(
                opacity: textFade,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus safety\nstarts with you.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Report any incident quickly and help others stay safe.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // fading the report button into the screen
            Positioned(
              left: 24,
              bottom: 28,
              child: FadeTransition(
                opacity: textFade,
                child: ElevatedButton.icon(
                  onPressed: widget.onReportPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DashboardPageState.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_alert_outlined,
                    size: 20,
                  ),
                  label: const Text(
                    'Report a Fire',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // sliding and floating the person
            Positioned(
              right: -14,
              bottom: -4,
              child: SlideTransition(
                position: personSlide,
                child: AnimatedBuilder(
                  animation: personFloatController,
                  child: Image.asset(
                    'assets/images/report_person.png',
                    width: 250,
                    height: 300,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox();
                    },
                  ),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, personFloat.value),
                      child: child,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const QuickAccessCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5EAF0),
            ),
            boxShadow: [
              BoxShadow(
                color: _DashboardPageState.navy
                    .withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  color: _DashboardPageState.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardNavigation extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DashboardNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<DashboardNavigation> createState() =>
      _DashboardNavigationState();
}

class _DashboardNavigationState extends State<DashboardNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController pulseController;
  late Animation<double> reportPulse;

  @override
  void initState() {
    super.initState();

    // controlling the report button pulse
    pulseController = AnimationController(
      duration: const Duration(milliseconds: 950),
      vsync: this,
    );

    // growing the report button slightly
    reportPulse = Tween<double>(
      begin: 1.0,
      end: 1.10,
    ).animate(
      CurvedAnimation(
        parent: pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // repeating the pulse animation
    pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: widget.selectedIndex,
          onTap: widget.onSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _DashboardPageState.coral,
          unselectedItemColor: Colors.black45,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),

            const BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Updates',
            ),

            BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: reportPulse,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _DashboardPageState.coral,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _DashboardPageState.coral
                            .withValues(alpha: 0.30),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
              ),
              label: 'Report',
            ),

            const BottomNavigationBarItem(
              icon: Icon(
                Icons.local_fire_department_outlined,
              ),
              activeIcon: Icon(
                Icons.local_fire_department,
              ),
              label: 'Your Fires',
            ),

            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
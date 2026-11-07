import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class YourFiresPage extends StatefulWidget {
  const YourFiresPage({super.key});

  @override
  State<YourFiresPage> createState() => _YourFiresPageState();
}

class _YourFiresPageState extends State<YourFiresPage>
    with TickerProviderStateMixin {
  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  final List<String> filters = ['All', 'Active', 'Resolved'];

  String selectedFilter = 'All';

  late final AnimationController entranceController;
  late final AnimationController fireController;

  late final Animation<double> pageOpacity;
  late final Animation<Offset> pagePosition;
  late final Animation<double> firePulse;

  @override
  void initState() {
    super.initState();

    // controlling the page entrance
    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    pageOpacity = CurvedAnimation(
      parent: entranceController,
      curve: Curves.easeOut,
    );

    pagePosition = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    // controlling the fire movement
    fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    firePulse = Tween<double>(
      begin: 0.92,
      end: 1.12,
    ).animate(CurvedAnimation(parent: fireController, curve: Curves.easeInOut));

    entranceController.forward();
    fireController.repeat(reverse: true);
  }

  @override
  void dispose() {
    entranceController.dispose();
    fireController.dispose();
    super.dispose();
  }

  // changing the selected filter
  void changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
  }

  // returning the status color
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
  DateTime incidentDate(Map<String, dynamic> incident) {
    final value = incident['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // opening the full incident
  void openIncident(Map<String, dynamic> incident) {
    final title = incident['title']?.toString() ?? 'Campus incident';

    final status = incident['status']?.toString() ?? 'Submitted';

    final category = incident['category']?.toString() ?? 'Other';

    final location = incident['location']?.toString() ?? 'ALU Campus';

    final description = incident['description']?.toString() ?? '';

    final imageUrl = incident['imageUrl']?.toString() ?? '';

    final color = statusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: imageUrl.isNotEmpty ? 0.86 : 0.70,
          minChildSize: 0.48,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 235,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }

                          return Container(
                            height: 235,
                            color: background,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: coral,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: background,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.black38,
                              size: 45,
                            ),
                          );
                        },
                      ),
                    ),

                  if (imageUrl.isNotEmpty) const SizedBox(height: 22),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      YourFireStatusBadge(
                        status: status,
                        color: color,
                        icon: statusIcon(status),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  YourFireProgress(currentStatus: status),

                  const SizedBox(height: 25),

                  YourFireInformationTile(
                    icon: Icons.category_outlined,
                    title: 'Category',
                    value: category,
                  ),

                  const SizedBox(height: 12),

                  YourFireInformationTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    value: location,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'What you reported',
                    style: TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    description.isEmpty
                        ? 'No description was provided.'
                        : description,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon(status), color: color),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current status',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                status,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          formatDate(
                            incident['updatedAt'] ?? incident['createdAt'],
                          ),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const YourFiresEmpty(
        title: 'Sign in required',
        message: 'Sign in to see the incidents you reported.',
      );
    }

    return Container(
      color: background,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // reading only incidents reported by this user
        stream: FirebaseFirestore.instance
            .collection('incidents')
            .where('reportedBy', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: coral));
          }

          if (snapshot.hasError) {
            return YourFiresError(message: snapshot.error.toString());
          }

          final documents = snapshot.data?.docs ?? [];

          final incidents = documents.map((document) {
            return <String, dynamic>{...document.data(), 'id': document.id};
          }).toList();

          // sorting reports from newest to oldest
          incidents.sort((first, second) {
            return incidentDate(second).compareTo(incidentDate(first));
          });

          final resolvedCount = incidents.where((incident) {
            final status = incident['status']?.toString() ?? '';

            return status.toLowerCase() == 'resolved';
          }).length;

          final activeCount = incidents.length - resolvedCount;

          final filteredIncidents = selectedFilter == 'All'
              ? incidents
              : selectedFilter == 'Resolved'
              ? incidents.where((incident) {
                  final status = incident['status']?.toString() ?? '';

                  return status.toLowerCase() == 'resolved';
                }).toList()
              : incidents.where((incident) {
                  final status = incident['status']?.toString() ?? '';

                  return status.toLowerCase() != 'resolved';
                }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 35),
            children: [
              FadeTransition(
                opacity: pageOpacity,
                child: SlideTransition(
                  position: pagePosition,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [coral, Color(0xFFFF795F)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: coral.withValues(alpha: 0.25),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -35,
                          top: -55,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        Positioned(
                          right: 55,
                          bottom: -65,
                          child: Container(
                            width: 125,
                            height: 125,
                            decoration: BoxDecoration(
                              color: navy.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ScaleTransition(
                                  scale: firePulse,
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'MY REPORTS',
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
                              ],
                            ),

                            const SizedBox(height: 19),

                            const Text(
                              'Your Fires',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Follow the incidents you reported and see how they are being handled.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 22),

                            Row(
                              children: [
                                YourFireSummary(
                                  number: '${incidents.length}',
                                  label: 'Total',
                                ),

                                const SizedBox(width: 10),

                                YourFireSummary(
                                  number: '$activeCount',
                                  label: 'Active',
                                ),

                                const SizedBox(width: 10),

                                YourFireSummary(
                                  number: '$resolvedCount',
                                  label: 'Resolved',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // showing report filters
              Row(
                children: filters.map((filter) {
                  final selected = selectedFilter == filter;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: filter == filters.last ? 0 : 9,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          changeFilter(filter);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? navy : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? navy : const Color(0xFFDCE5EE),
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: navy.withValues(alpha: 0.18),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: selected ? Colors.white : navy,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedFilter == 'All'
                          ? 'All your reports'
                          : '$selectedFilter reports',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: coral.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${filteredIncidents.length}',
                      style: const TextStyle(
                        color: coral,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (filteredIncidents.isEmpty)
                YourFiresEmpty(
                  title: selectedFilter == 'All'
                      ? 'You have not reported an incident'
                      : 'No $selectedFilter reports',
                  message: selectedFilter == 'All'
                      ? 'Reports you submit will appear here.'
                      : 'Your $selectedFilter reports will appear here.',
                )
              else
                Column(
                  children: List.generate(filteredIncidents.length, (index) {
                    final incident = filteredIncidents[index];

                    final status =
                        incident['status']?.toString() ?? 'Submitted';

                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 350 + (index * 80)),
                      curve: Curves.easeOutBack,
                      builder: (context, animation, child) {
                        return Opacity(
                          opacity: animation.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(30 * (1 - animation), 0),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: YourFireCard(
                          incident: incident,
                          date: formatDate(
                            incident['updatedAt'] ?? incident['createdAt'],
                          ),
                          color: statusColor(status),
                          icon: statusIcon(status),
                          onPressed: () {
                            openIncident(incident);
                          },
                        ),
                      ),
                    );
                  }),
                ),
            ],
          );
        },
      ),
    );
  }
}

class YourFireCard extends StatelessWidget {
  const YourFireCard({
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
  static const Color coral = Color(0xFFFF5A3C);
  static const Color background = Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    final title = incident['title']?.toString() ?? 'Campus incident';

    final status = incident['status']?.toString() ?? 'Submitted';

    final location = incident['location']?.toString() ?? 'ALU Campus';

    final imageUrl = incident['imageUrl']?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: coral.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: navy.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 92,
                            height: 108,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) {
                                return child;
                              }

                              return Container(
                                width: 92,
                                height: 108,
                                color: background,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return YourFirePlaceholder(
                                color: color,
                                icon: icon,
                              );
                            },
                          )
                        : YourFirePlaceholder(color: color, icon: icon),
                  ),

                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: coral,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    YourFireStatusBadge(
                      status: status,
                      color: color,
                      icon: icon,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.black38,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.black38,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: navy.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: navy,
                            size: 16,
                          ),
                        ),
                      ],
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

class YourFireProgress extends StatelessWidget {
  const YourFireProgress({super.key, required this.currentStatus});

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
      (stage) => stage.toLowerCase() == currentStatus.toLowerCase(),
    );

    return index < 0 ? 0 : index;
  }

  IconData stageIcon(String stage) {
    switch (stage) {
      case 'Verified':
        return Icons.verified_rounded;

      case 'In Progress':
        return Icons.construction_rounded;

      case 'Resolved':
        return Icons.task_alt_rounded;

      default:
        return Icons.pending_actions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = currentIndex / (stages.length - 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report progress',
            style: TextStyle(
              color: navy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Stack(
            children: [
              Positioned(
                top: 17,
                left: 26,
                right: 26,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E0E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Positioned(
                top: 17,
                left: 26,
                right: 26,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 4,
                      decoration: BoxDecoration(
                        color: coral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

              Row(
                children: List.generate(stages.length, (index) {
                  final stage = stages[index];
                  final completed = index <= currentIndex;
                  final active = index == currentIndex;

                  return Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: active ? 39 : 35,
                          height: active ? 39 : 35,
                          decoration: BoxDecoration(
                            color: completed ? coral : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: completed
                                  ? coral
                                  : const Color(0xFFD7E0E9),
                              width: 2,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: coral.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            stageIcon(stage),
                            color: completed ? Colors.white : Colors.black38,
                            size: 18,
                          ),
                        ),

                        const SizedBox(height: 8),

                        FittedBox(
                          child: Text(
                            stage,
                            style: TextStyle(
                              color: completed ? navy : Colors.black38,
                              fontSize: 10,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class YourFireStatusBadge extends StatelessWidget {
  const YourFireStatusBadge({
    super.key,
    required this.status,
    required this.color,
    required this.icon,
  });

  final String status;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class YourFireInformationTile extends StatelessWidget {
  const YourFireInformationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  static const Color navy = Color(0xFF12355B);
  static const Color background = Color(0xFFF4F7FB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: navy),
          const SizedBox(width: 11),
          Text(
            '$title:',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class YourFireSummary extends StatelessWidget {
  const YourFireSummary({super.key, required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class YourFirePlaceholder extends StatelessWidget {
  const YourFirePlaceholder({
    super.key,
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 108,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Icon(icon, color: color, size: 37),
    );
  }
}

class YourFiresEmpty extends StatelessWidget {
  const YourFiresEmpty({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            color: Color(0xFFFF5A3C),
            size: 62,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF12355B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class YourFiresError extends StatelessWidget {
  const YourFiresError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 55),
            const SizedBox(height: 14),
            const Text(
              'Your reports could not be loaded',
              style: TextStyle(
                color: Color(0xFF12355B),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

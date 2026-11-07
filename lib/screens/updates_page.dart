import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage>
    with TickerProviderStateMixin {
  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  final List<String> statuses = ['All', 'Submitted', 'Verified', 'Resolved'];

  String selectedStatus = 'All';
  int visibleCount = 5;

  final TextEditingController searchController = TextEditingController();

  String searchText = '';

  bool? currentUserIsStudent;
  String currentUserId = '';

  late final AnimationController entranceController;
  late final AnimationController pulseController;

  late final Animation<double> headerOpacity;
  late final Animation<Offset> headerPosition;
  late final Animation<double> pulseAnimation;

  @override
  void initState() {
    super.initState();

    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    headerOpacity = CurvedAnimation(
      parent: entranceController,
      curve: Curves.easeOut,
    );

    headerPosition =
        Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    pulseAnimation = Tween<double>(begin: 0.75, end: 1.18).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    entranceController.forward();
    pulseController.repeat(reverse: true);

    loadCurrentUserRole();
  }

  @override
  void dispose() {
    searchController.dispose();
    entranceController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  // checking whether the signed-in user is a student
  Future<void> loadCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    currentUserId = user.uid;

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDocument.data()?['role']?.toString() ?? 'Student';

      if (!mounted) return;

      setState(() {
        currentUserIsStudent = role.toLowerCase() == 'student';
      });
    } catch (error) {
      if (!mounted) return;

      // keeping personal information hidden if the role fails to load
      setState(() {
        currentUserIsStudent = true;
      });
    }
  }

  // changing the selected status
  void selectStatus(String status) {
    setState(() {
      selectedStatus = status;
      visibleCount = 5;
    });
  }

  // showing five more updates
  void viewMore(int total) {
    setState(() {
      visibleCount += 5;

      if (visibleCount > total) {
        visibleCount = total;
      }
    });
  }

  // returning to the first five updates
  void viewLess() {
    setState(() {
      visibleCount = 5;
    });
  }

  // updating the incident search
  void updateSearch(String value) {
    setState(() {
      searchText = value.trim().toLowerCase();
      visibleCount = 5;
    });
  }

  // clearing the incident search
  void clearSearch() {
    searchController.clear();

    setState(() {
      searchText = '';
      visibleCount = 5;
    });
  }

  // opening the incident search
  void openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSearchState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCE4ED),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFFFFE5DF),
                            child: Icon(Icons.search_rounded, color: coral),
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Search incidents',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Search by title, category or location',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          updateSearch(value);
                          setSearchState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Example: fire, water or library',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: navy,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    clearSearch();
                                    setSearchState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.black45,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 17,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCE5EE),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: coral,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(
                            'Show results',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // returning the color for each status
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

  // returning the icon for each status
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

  // updating the status as a staff member
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String reporterId,
    required String newStatus,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final incidentReference = firestore
          .collection('incidents')
          .doc(incidentId);

      final batch = firestore.batch();

      batch.update(incidentReference, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });

      // notifying the student who made the report
      if (reporterId.isNotEmpty) {
        final notificationReference = firestore
            .collection('notifications')
            .doc();

        batch.set(notificationReference, {
          'userId': reporterId,
          'incidentId': incidentId,
          'title': 'Incident status updated',
          'message': 'Your report is now $newStatus.',
          'type': 'status_updated',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incident updated to $newStatus.'),
          backgroundColor: mint,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // deleting a fake or invalid report as an admin
  Future<void> deleteIncident({
    required String incidentId,
    required String incidentTitle,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: Colors.red,
              size: 30,
            ),
          ),
          title: const Text(
            'Delete this report?',
            textAlign: TextAlign.center,
            style: TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '"$incidentTitle" will be permanently removed. '
            'Only delete fake, duplicate, or invalid reports.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel', style: TextStyle(color: navy)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // getting notifications connected to the incident
      final notifications = await firestore
          .collection('notifications')
          .where('incidentId', isEqualTo: incidentId)
          .get();

      final batch = firestore.batch();

      // deleting the incident
      batch.delete(firestore.collection('incidents').doc(incidentId));

      // deleting notifications connected to the incident
      for (final notification in notifications.docs) {
        batch.delete(notification.reference);
      }

      await batch.commit();

      if (!mounted) return;

      // closing the incident details
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The report was deleted successfully.'),
          backgroundColor: mint,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The report could not be deleted: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // opening the incident details
  Future<void> openIncident(Map<String, dynamic> incident) async {
    final incidentId = incident['id']?.toString() ?? '';

    final reporterId = incident['reportedBy']?.toString() ?? '';

    final isStaff = currentUserIsStudent == false;

    int reporterIncidentCount = 0;

    // counting reports only when a staff member opens the incident
    if (isStaff && reporterId.isNotEmpty) {
      try {
        final reporterIncidents = await FirebaseFirestore.instance
            .collection('incidents')
            .where('reportedBy', isEqualTo: reporterId)
            .get();

        reporterIncidentCount = reporterIncidents.docs.length;
      } catch (error) {
        debugPrint('Could not count reporter incidents: $error');
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('incidents')
              .doc(incidentId)
              .snapshots(),
          builder: (context, snapshot) {
            final liveIncident = snapshot.data?.data() ?? incident;

            final title =
                liveIncident['title']?.toString() ?? 'Campus incident';

            final status = liveIncident['status']?.toString() ?? 'Submitted';

            final category = liveIncident['category']?.toString() ?? 'Other';

            final location =
                liveIncident['location']?.toString() ?? 'ALU Campus';

            final description = liveIncident['description']?.toString() ?? '';

            final imageUrl = liveIncident['imageUrl']?.toString() ?? '';

            final reporterName =
                liveIncident['reporterName']?.toString() ?? 'CampusFire User';

            final reporterEmail =
                liveIncident['reporterEmail']?.toString() ?? '';

            final color = statusColor(status);

            return DraggableScrollableSheet(
              initialChildSize: imageUrl.isNotEmpty ? 0.88 : 0.78,
              minChildSize: 0.50,
              maxChildSize: 0.95,
              builder: (context, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
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
                                  size: 44,
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

                          const SizedBox(width: 12),

                          StatusBadge(
                            status: status,
                            color: color,
                            icon: statusIcon(status),
                          ),
                        ],
                      ),

                      // showing the reporter compactly to staff
                      if (isStaff) ...[
                        const SizedBox(height: 13),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ReporterCornerCard(
                            reporterName: reporterName,
                            reporterEmail: reporterEmail,
                            incidentCount: reporterIncidentCount,
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),

                      // showing all four progress stages
                      IncidentProgressTracker(currentStatus: status),

                      const SizedBox(height: 25),

                      InformationTile(
                        icon: Icons.category_outlined,
                        title: 'Category',
                        value: category,
                      ),

                      const SizedBox(height: 12),

                      InformationTile(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: location,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'What happened',
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

                      // allowing only staff to change status
                      if (isStaff) ...[
                        const SizedBox(height: 27),

                        const Text(
                          'Manage incident',
                          style: TextStyle(
                            color: navy,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 11),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: const Color(0xFFDCE5EE)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value:
                                  const [
                                    'Submitted',
                                    'Verified',
                                    'In Progress',
                                    'Resolved',
                                  ].contains(status)
                                  ? status
                                  : 'Submitted',
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: navy,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Submitted',
                                  child: StatusDropdownItem(
                                    title: 'Submitted',
                                    icon: Icons.pending_actions_rounded,
                                    color: coral,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Verified',
                                  child: StatusDropdownItem(
                                    title: 'Verified',
                                    icon: Icons.verified_rounded,
                                    color: Color(0xFF3787E5),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'In Progress',
                                  child: StatusDropdownItem(
                                    title: 'In Progress',
                                    icon: Icons.construction_rounded,
                                    color: Colors.orange,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Resolved',
                                  child: StatusDropdownItem(
                                    title: 'Resolved',
                                    icon: Icons.task_alt_rounded,
                                    color: mint,
                                  ),
                                ),
                              ],
                              onChanged: (newStatus) async {
                                if (newStatus == null || newStatus == status) {
                                  return;
                                }

                                await updateIncidentStatus(
                                  incidentId: incidentId,
                                  reporterId: reporterId,
                                  newStatus: newStatus,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Divider(color: Color(0xFFE1E8F0)),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              deleteIncident(
                                incidentId: incidentId,
                                incidentTitle: title,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(
                                color: Colors.red.withValues(alpha: 0.35),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text(
                              'Delete fake report',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: background,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            // reading every incident
            stream: FirebaseFirestore.instance
                .collection('incidents')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: coral),
                );
              }

              if (snapshot.hasError) {
                return UpdatesError(message: snapshot.error.toString());
              }

              final documents = snapshot.data?.docs ?? [];

              final incidents = documents.map((document) {
                return <String, dynamic>{...document.data(), 'id': document.id};
              }).toList();

              final filteredIncidents = incidents.where((incident) {
                final status =
                    incident['status']?.toString().trim().toLowerCase() ??
                    'submitted';

                bool matchesStatus;

                switch (selectedStatus.toLowerCase()) {
                  case 'submitted':
                    matchesStatus = status == 'submitted';
                    break;

                  case 'verified':
                    matchesStatus =
                        status == 'verified' || status == 'in progress';
                    break;

                  case 'resolved':
                    matchesStatus = status == 'resolved';
                    break;

                  default:
                    matchesStatus = true;
                }

                final searchableInformation = [
                  incident['title'],
                  incident['category'],
                  incident['location'],
                  incident['description'],
                ].where((value) => value != null).join(' ').toLowerCase();

                final matchesSearch =
                    searchText.isEmpty ||
                    searchableInformation.contains(searchText);

                return matchesStatus && matchesSearch;
              }).toList();

              final amountToShow = visibleCount > filteredIncidents.length
                  ? filteredIncidents.length
                  : visibleCount;

              final displayedIncidents = filteredIncidents
                  .take(amountToShow)
                  .toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 105),
                children: [
                  FadeTransition(
                    opacity: headerOpacity,
                    child: SlideTransition(
                      position: headerPosition,
                      child: Container(
                        padding: const EdgeInsets.all(21),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [navy, Color(0xFF1D5685)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: navy.withValues(alpha: 0.22),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30,
                              top: -45,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: coral.withValues(alpha: 0.16),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),

                            Positioned(
                              right: 55,
                              bottom: -55,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: mint.withValues(alpha: 0.13),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 49,
                                      height: 49,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.campaign_rounded,
                                        color: Colors.white,
                                        size: 27,
                                      ),
                                    ),

                                    const Spacer(),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          ScaleTransition(
                                            scale: pulseAnimation,
                                            child: Container(
                                              width: 9,
                                              height: 9,
                                              decoration: const BoxDecoration(
                                                color: mint,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 19),

                                const Text(
                                  'Campus Updates',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                const Text(
                                  'Track every report from submission to resolution.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 19),

                                Row(
                                  children: [
                                    Text(
                                      '${incidents.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    const Text(
                                      'total reports',
                                      style: TextStyle(color: Colors.white70),
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

                  const Text(
                    'Filter by status',
                    style: TextStyle(
                      color: navy,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: statuses.map((status) {
                      final selected = selectedStatus == status;

                      final color = status == 'All'
                          ? navy
                          : statusColor(status);

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: status == statuses.last ? 0 : 8,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              selectStatus(status);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? color : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? color
                                      : const Color(0xFFDCE5EE),
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.22),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    status == 'All'
                                        ? Icons.grid_view_rounded
                                        : statusIcon(status),
                                    size: 20,
                                    color: selected ? Colors.white : color,
                                  ),
                                  const SizedBox(height: 5),
                                  FittedBox(
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: selected ? Colors.white : navy,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
                          selectedStatus == 'All'
                              ? 'Recent reports'
                              : '$selectedStatus reports',
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
                          color: navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '${filteredIncidents.length}',
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (filteredIncidents.isEmpty)
                    EmptyStatus(
                      status: selectedStatus,
                      searchText: searchController.text.trim(),
                    )
                  else
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        key: ValueKey('$selectedStatus-$amountToShow'),
                        children: List.generate(displayedIncidents.length, (
                          index,
                        ) {
                          final incident = displayedIncidents[index];

                          final status =
                              incident['status']?.toString() ?? 'Submitted';

                          final isOwnReport =
                              currentUserIsStudent == true &&
                              incident['reportedBy']?.toString() ==
                                  currentUserId;

                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 350 + (index * 90),
                            ),
                            curve: Curves.easeOutBack,
                            builder: (context, animation, child) {
                              return Opacity(
                                opacity: animation.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(35 * (1 - animation), 0),
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: CoolUpdateCard(
                                incident: incident,
                                date: formatDate(
                                  incident['updatedAt'] ??
                                      incident['createdAt'],
                                ),
                                color: statusColor(status),
                                icon: statusIcon(status),
                                isOwnReport: isOwnReport,
                                onPressed: () {
                                  openIncident(incident);
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  if (filteredIncidents.length > 5)
                    Row(
                      children: [
                        if (visibleCount > 5)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: viewLess,
                              icon: const Icon(Icons.keyboard_arrow_up_rounded),
                              label: const Text('View less'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: navy,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(color: navy),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                        if (visibleCount > 5 &&
                            amountToShow < filteredIncidents.length)
                          const SizedBox(width: 10),

                        if (amountToShow < filteredIncidents.length)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                viewMore(filteredIncidents.length);
                              },
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              label: Text(
                                'View more '
                                '(${filteredIncidents.length - amountToShow})',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: coral,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        Positioned(
          right: 20,
          bottom: 18,
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: openSearch,
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  constraints: const BoxConstraints(maxWidth: 230),
                  padding: EdgeInsets.symmetric(
                    horizontal: searchText.isEmpty ? 18 : 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: searchText.isEmpty ? navy : coral,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (searchText.isEmpty ? navy : coral).withValues(
                          alpha: 0.28,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 22,
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Text(
                          searchText.isEmpty
                              ? 'Search incidents'
                              : searchController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (searchText.isNotEmpty) ...[
                        const SizedBox(width: 7),

                        GestureDetector(
                          onTap: clearSearch,
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CoolUpdateCard extends StatelessWidget {
  const CoolUpdateCard({
    super.key,
    required this.incident,
    required this.date,
    required this.color,
    required this.icon,
    required this.isOwnReport,
    required this.onPressed,
  });

  final Map<String, dynamic> incident;
  final String date;
  final Color color;
  final IconData icon;
  final bool isOwnReport;
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
            border: Border.all(
              color: isOwnReport
                  ? coral.withValues(alpha: 0.45)
                  : color.withValues(alpha: 0.18),
              width: isOwnReport ? 1.5 : 1,
            ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 92,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }

                          return Container(
                            width: 92,
                            height: 100,
                            color: background,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return StatusImagePlaceholder(
                            color: color,
                            icon: icon,
                          );
                        },
                      )
                    : StatusImagePlaceholder(color: color, icon: icon),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(status: status, color: color, icon: icon),

                        const Spacer(),

                        // marking incidents submitted by this student
                        if (isOwnReport)
                          Tooltip(
                            message: 'You reported this',
                            child: Container(
                              width: 29,
                              height: 29,
                              decoration: BoxDecoration(
                                color: coral.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: coral,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 9),

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

                    const SizedBox(height: 9),

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

                    const SizedBox(height: 6),

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
                          width: 27,
                          height: 27,
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

class IncidentProgressTracker extends StatelessWidget {
  const IncidentProgressTracker({super.key, required this.currentStatus});

  final String currentStatus;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);

  // in progress is shown here but not in the page filters
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
            'Incident progress',
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
                      curve: Curves.easeOut,
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

class ReporterCornerCard extends StatelessWidget {
  const ReporterCornerCard({
    super.key,
    required this.reporterName,
    required this.reporterEmail,
    required this.incidentCount,
  });

  final String reporterName;
  final String reporterEmail;
  final int incidentCount;

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 265),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: navy,
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),

          const SizedBox(width: 9),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reported by',
                  style: TextStyle(color: Colors.black45, fontSize: 9),
                ),
                Text(
                  reporterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (reporterEmail.isNotEmpty)
                  Text(
                    reporterEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black45, fontSize: 9),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: coral.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$incidentCount',
                  style: const TextStyle(
                    color: coral,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'reports',
                  style: TextStyle(
                    color: coral,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
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

class StatusDropdownItem extends StatelessWidget {
  const StatusDropdownItem({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF12355B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class StatusImagePlaceholder extends StatelessWidget {
  const StatusImagePlaceholder({
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
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: Icon(icon, color: color, size: 36),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
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

class InformationTile extends StatelessWidget {
  const InformationTile({
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

class EmptyStatus extends StatelessWidget {
  const EmptyStatus({
    super.key,
    required this.status,
    required this.searchText,
  });

  final String status;
  final String searchText;

  @override
  Widget build(BuildContext context) {
    final isSearching = searchText.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.notifications_none_rounded,
            color: const Color(0xFF2EC4B6),
            size: 60,
          ),

          const SizedBox(height: 14),

          Text(
            isSearching
                ? 'No matching incidents'
                : status == 'All'
                ? 'No updates yet'
                : 'No $status reports',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF12355B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            isSearching
                ? 'No reports were found for "$searchText". '
                      'Try another title, category or location.'
                : 'Incident status updates will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class UpdatesError extends StatelessWidget {
  const UpdatesError({super.key, required this.message});

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
              'Updates could not be loaded',
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

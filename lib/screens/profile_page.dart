import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color navy = Color(0xFF12355B);
  static const Color coral = Color(0xFFFF5A3C);
  static const Color mint = Color(0xFF2EC4B6);
  static const Color background = Color(0xFFF4F7FB);

  // confirming and signing the user out
  Future<void> logout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFE8E2),
            child: Icon(Icons.logout, color: coral),
          ),
          title: const Text(
            'Log out?',
            textAlign: TextAlign.center,
            style: TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You will need to sign in again to access CampusFire.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: navy,
                side: const BorderSide(color: Color(0xFFD8E0E8)),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: coral,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await authProvider.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final authProvider = context.watch<AuthProvider>();

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator(color: coral));
    }

    return Container(
      color: background,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data();

          final fullName =
              userData?['fullName'] as String? ??
              currentUser.displayName ??
              'CampusFire User';

          final email =
              userData?['email'] as String? ?? currentUser.email ?? '';

          final role = userData?['role'] as String? ?? 'Student';

          final status = userData?['status'] as String? ?? 'active';

          final firstLetter = fullName.isNotEmpty
              ? fullName[0].toUpperCase()
              : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 35),
            child: Column(
              children: [
                const Text(
                  'Your Profile',
                  style: TextStyle(
                    color: navy,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Manage your CampusFire account.',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),

                const SizedBox(height: 26),

                // showing the user's profile details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 47,
                        backgroundColor: navy.withValues(alpha: 0.10),
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: mint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            color: mint,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // showing the account information
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5EAF0)),
                  ),
                  child: Column(
                    children: [
                      ProfileInformation(
                        icon: Icons.badge_outlined,
                        title: 'Account role',
                        value: role,
                      ),

                      const Divider(height: 28),

                      ProfileInformation(
                        icon: Icons.verified_user_outlined,
                        title: 'Account status',
                        value: status == 'active'
                            ? 'Active'
                            : 'Pending approval',
                      ),

                      const Divider(height: 28),

                      ProfileInformation(
                        icon: Icons.email_outlined,
                        title: 'Email verification',
                        value: currentUser.emailVerified
                            ? 'Verified'
                            : 'Not verified',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // signing the user out
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            logout(context);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: coral,
                      side: const BorderSide(color: coral),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: coral,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.logout),
                    label: Text(
                      authProvider.isLoading ? 'Logging out...' : 'Log Out',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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

class ProfileInformation extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInformation({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: ProfilePage.navy.withValues(alpha: 0.08),
          child: Icon(icon, color: ProfilePage.navy, size: 21),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.black45, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: ProfilePage.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

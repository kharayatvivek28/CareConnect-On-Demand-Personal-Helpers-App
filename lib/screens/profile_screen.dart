import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginproject/screens/bookings_screen.dart';

import '../utils/logout.dart';
import 'manage_address_screen.dart';
import 'complete_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String displayName = '';
  String phone = '';
  String avatarUrl = ''; // could be DiceBear avatar or Google photoURL

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    String defaultAvatarUrl =
        "https://avatars.dicebear.com/api/initials/${user!.displayName?.replaceAll(' ', '') ?? user!.uid}.png";

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        displayName = data['displayName'] ?? user!.displayName ?? 'User';
        phone = data['phone'] ?? user!.phoneNumber ?? '';
        avatarUrl = data['photoUrl'] != null && data['photoUrl'].isNotEmpty
            ? data['photoUrl']
            : defaultAvatarUrl;
        _isLoading = false;
      });
    } else {
      setState(() {
        displayName = user!.displayName ?? 'User';
        phone = user!.phoneNumber ?? '';
        avatarUrl = user!.photoURL != null && user!.photoURL!.isNotEmpty
            ? user!.photoURL!
            : defaultAvatarUrl;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileOptions = [
      {
        'id': 'complete-profile',
        'label': 'Complete Your Profile',
        'icon': Icons.person,
        'description': 'Add more details to get better service',
        'color': const Color(0xFF6366F1),
      },
      {
        'id': 'manage-addresses',
        'label': 'Manage Addresses',
        'icon': Icons.location_on,
        'description': 'Home, Work & Other addresses',
        'color': Colors.grey.shade700,
      },
      {
        'id': 'payment-methods',
        'label': 'Payment Methods',
        'icon': Icons.credit_card,
        'description': 'Cards, UPI & Wallet',
        'color': Colors.grey.shade700,
      },
      {
        'id': 'settings',
        'label': 'Settings',
        'icon': Icons.settings,
        'description': 'Notifications, Privacy & More',
        'color': Colors.grey.shade700,
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(color: Color(0xFF6366F1)),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+91 $phone',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quick Actions Cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BookingsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF6366F1),
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'My Bookings',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'View & manage',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    color: Color(0xFF6366F1),
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Help & Support',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Get assistance',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Options
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: profileOptions.length,
                    itemBuilder: (context, index) {
                      final option = profileOptions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            switch (option['id']) {
                              case 'complete-profile':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CompleteProfileScreen(),
                                  ),
                                );
                                break;
                              case 'manage-addresses':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ManageAddressScreen(),
                                  ),
                                );
                                break;
                              case 'payment-methods':
                                break;
                              case 'settings':
                                _showProfileBottomSheet(context);
                                break;
                            }
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              option['icon'] as IconData,
                              color: option['color'] as Color,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            option['label'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            option['description'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showLogoutDialog(context);
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🧱 Reusable content for the modal bottom sheet
  Widget _buildBottomSheetContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.dark_mode, color: Colors.deepPurple),
          title: const Text('Dark Mode'),
          subtitle: const Text('Switch theme (coming soon)'),
          onTap: () => Navigator.pop(context),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications, color: Colors.orange),
          title: const Text('Notifications'),
          subtitle: const Text('Manage notification preferences'),
          onTap: () => Navigator.pop(context),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.privacy_tip, color: Colors.blue),
          title: const Text('Privacy & Security'),
          subtitle: const Text('Permissions and data settings'),
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // 👇 Tap-triggered modal version (for Settings button)
  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildBottomSheetContent(context),
          ),
        ),
      ),
    );
  }
}

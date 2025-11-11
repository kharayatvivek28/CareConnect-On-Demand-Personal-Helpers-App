import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🔹 Cache to avoid multiple Firestore reads for the same provider
  final Map<String, Map<String, dynamic>> _providerCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('Active'),
          _buildBookingsList('Completed'),
          _buildBookingsList('Cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String status) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user!.uid)
          .where('status', isEqualTo: status)
          .orderBy('date', descending: true)
          .snapshots()
          .handleError((error) {
            if (kDebugMode) print("⚠️ Firestore error: $error");
          }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Unable to fetch bookings. Please try again later.",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              status == 'Active'
                  ? "You have no active bookings"
                  : "No $status bookings yet",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final booking = doc.data() as Map<String, dynamic>;

            final providerId = booking['providerId'];
            final dateField = booking['date'];
            final date = dateField is Timestamp
                ? dateField.toDate()
                : DateTime.now();
            final formattedDate = "${date.day}/${date.month}/${date.year}";
            final addons = (booking['addons'] as List?) ?? [];
            final totalPrice =
                booking['totalPrice'] ?? booking['basePrice'] ?? 0;

            // 🔹 Wrap the card in a FutureBuilder for dynamic provider data
            return FutureBuilder<Map<String, dynamic>?>(
              future: _getProviderData(providerId),
              builder: (context, providerSnapshot) {
                final providerData = providerSnapshot.data;
                final providerName =
                    (providerData?['name'] ??
                            booking['providerName'] ??
                            'Partner')
                        .toString();

                final providerPhone =
                    (providerData?['phone'] ?? booking['providerPhone'] ?? '')
                        .toString();

                final providerRating = (providerData?['ratingAvg'] ?? '4.0')
                    .toString();

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              booking['serviceName'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "₹$totalPrice",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('By $providerName'),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 3),
                                Text(providerRating),
                              ],
                            ),
                          ],
                        ),
                        if (providerPhone != null &&
                            providerPhone.toString().isNotEmpty)
                          Text(
                            "📞 ${providerPhone.toString()}",
                            style: const TextStyle(color: Colors.black54),
                          ),

                        const SizedBox(height: 4),
                        Text('On $formattedDate'),
                        if (addons.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Add-ons: ${addons.join(', ')}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        const SizedBox(height: 8),

                        // 🔹 Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              status,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // 🔹 Action Buttons (only for Active)
                        if (status == 'Active') ...[
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _confirmCancelBooking(doc.id),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text("Cancel Booking"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _confirmCompleteBooking(doc.id),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text("Mark Completed"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ✅ Fetch and cache provider data
  Future<Map<String, dynamic>?> _getProviderData(String? providerId) async {
    if (providerId == null || providerId.isEmpty) return null;

    if (_providerCache.containsKey(providerId)) {
      return _providerCache[providerId];
    }

    final doc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(providerId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _providerCache[providerId] = data; // cache for reuse
      return data;
    }
    return null;
  }

  // 🔹 Cancel Booking
  Future<void> _confirmCancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: const Text(
          "Are you sure you want to cancel this booking?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'Cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking cancelled successfully."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // 🔹 Complete Booking
  Future<void> _confirmCompleteBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complete Booking"),
        content: const Text(
          "Mark this booking as completed?\nIt will move to the Completed tab.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Yes, Complete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'Completed',
            'completedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking marked as completed."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 🔹 Helper color function
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.blueAccent;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

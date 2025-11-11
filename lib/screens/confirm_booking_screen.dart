import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;

  const ConfirmBookingScreen({super.key, required this.serviceData});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  DateTime? selectedDate;
  String? selectedAddress;
  List<String> selectedAddons = [];
  bool isLoading = false;

  // ✅ For providers
  List<Map<String, dynamic>> availableProviders = [];
  Map<String, dynamic>? selectedProvider;
  String? userCity;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndProviders();
  }

  // 🔹 Load user's city and default address first
  Future<void> _loadUserDataAndProviders() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final data = doc.data() as Map<String, dynamic>;

    // ✅ Get user's base city and address
    String? city = data['baseCity'];
    String? defaultAddr;
    if (data['addresses'] != null &&
        data['addresses'] is List &&
        (data['addresses'] as List).isNotEmpty) {
      final addresses = List<Map<String, dynamic>>.from(data['addresses']);
      final defaultAddress = addresses.firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => addresses[0],
      );
      defaultAddr = defaultAddress['fullAddress'] ?? '';
    }

    setState(() {
      userCity = city ?? 'chandigarh';
      selectedAddress = defaultAddr ?? '';
    });

    // ✅ Fetch providers only after we get the city
    _fetchProvidersForService();
  }

  // 🔹 Fetch providers based on user's city and service profession
  Future<void> _fetchProvidersForService() async {
    if (userCity == null) return;

    final service = widget.serviceData;
    final serviceName = (service['name'] ?? '').toString().toLowerCase().trim();
    final serviceWords = serviceName.split(RegExp(r'\s+'));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('providers')
          .where('availability', isEqualTo: true)
          .get();

      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        final providerCity = (data['baseCity'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        if (providerCity != userCity!.toLowerCase()) return false;

        final profession = (data['profession'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final skills = List<String>.from(
          data['skills'] ?? [],
        ).map((s) => s.toLowerCase()).toList();

        final allWords = [
          ...profession.split(RegExp(r'\s+')),
          ...skills.expand((s) => s.split(RegExp(r'\s+'))),
        ];

        return serviceWords.any((word) => allWords.contains(word));
      }).toList();

      print(
        "🟣 Found ${filtered.length} providers for service: $serviceName in city: $userCity",
      );
      for (var d in filtered) {
        final data = d.data();
        print(
          "✅ Provider: ${data['name']} | City: ${data['baseCity']} | Profession: ${data['profession']}",
        );
      }

      setState(() {
        availableProviders = filtered.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // ✅ add document ID to provider data
          return data;
        }).toList();
      });
    } catch (e) {
      print("❌ Error fetching providers: $e");
    }
  }

  // 🔹 Confirm Booking
  Future<void> _confirmBooking() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a date")));
      return;
    }

    if (selectedAddress == null || selectedAddress!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an address")));
      return;
    }

    if (selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a service provider")),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final service = widget.serviceData;
    double totalPrice = _calculateTotalPrice(service);

    final bookingData = {
      'userId': user!.uid,
      'serviceId': service['id'] ?? '',
      'serviceName': service['name'] ?? '',
      'addons': selectedAddons,
      'totalPrice': totalPrice,
      'date': Timestamp.fromDate(selectedDate!),
      'address': selectedAddress,
      'providerId': selectedProvider!['id'], // ✅ use Firestore doc ID
      'providerName': selectedProvider!['name'] ?? '',
      'providerPhone': selectedProvider!['phone'] ?? '',
      'basePrice': service['basePrice'] ?? 0,
      'status': 'Active',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('bookings').add(bookingData);

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking confirmed successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.serviceData;
    final addons = List<Map<String, dynamic>>.from(
      (service['addons'] ?? []).map((a) => Map<String, dynamic>.from(a)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Service Info
                  Text(
                    service['name'] ?? 'Service',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Base Price: ₹${service['basePrice'] ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (service['description'] != null)
                    Text(
                      service['description'],
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 🔹 Date Picker
                  const Text(
                    'Select Date',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null
                                ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                : "Tap to select date",
                            style: TextStyle(
                              color: selectedDate != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF6366F1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Address
                  const Text(
                    'Service Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      selectedAddress ?? "Loading address...",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Providers Section
                  const Text(
                    'Select Service Provider',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: availableProviders.isEmpty
                        ? const Text(
                            "No providers available for this service in your city.",
                            style: TextStyle(color: Colors.grey),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              isExpanded: true,
                              hint: const Text("Select a provider"),
                              value: selectedProvider,
                              onChanged: (value) {
                                setState(() => selectedProvider = value);
                              },
                              items: availableProviders.map((provider) {
                                return DropdownMenuItem(
                                  value: provider,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(provider['name'] ?? 'Unknown'),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          Text(
                                            '${provider['ratingAvg'] ?? '4.0'}',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Addons Section
                  if (addons.isNotEmpty) ...[
                    const Text(
                      'Add-ons',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: addons.map((addon) {
                        final isSelected = selectedAddons.contains(
                          addon['name'],
                        );
                        return CheckboxListTile(
                          activeColor: const Color(0xFF6366F1),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedAddons.add(addon['name']);
                              } else {
                                selectedAddons.remove(addon['name']);
                              }
                            });
                          },
                          title: Text(addon['name']),
                          secondary: Text(
                            '₹${addon['price']}',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),

      // 🔹 Bottom Total + Confirm Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Total: ₹${_calculateTotalPrice(service).toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmBooking,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalPrice(Map<String, dynamic> service) {
    double total = (service['basePrice'] ?? 0).toDouble();
    final addonsList = List<Map<String, dynamic>>.from(
      (service['addons'] ?? []).map((a) => Map<String, dynamic>.from(a)),
    );
    for (var addon in addonsList) {
      if (selectedAddons.contains(addon['name'])) {
        total += (addon['price'] ?? 0).toDouble();
      }
    }
    return total;
  }
}

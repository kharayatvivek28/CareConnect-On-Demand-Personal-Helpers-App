import 'package:flutter/material.dart';

import 'confirm_booking_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const ServiceDetailsScreen({super.key, required this.serviceData});

  @override
  Widget build(BuildContext context) {
    final image = serviceData['image'] ?? '';
    final name = serviceData['name'] ?? 'Service';
    final desc = serviceData['description'] ?? 'No description available';
    final basePrice = serviceData['basePrice'] ?? 0;
    final unit = serviceData['unit'] ?? '';
    final addons = List<Map<String, dynamic>>.from(
      (serviceData['addons'] ?? []).map((a) => Map<String, dynamic>.from(a)),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Service Image Header
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Image.asset(
                  image,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 80),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Service Title
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Base Price
                  Text(
                    'Starting from ₹$basePrice ${unit.isNotEmpty ? "/ $unit" : ""}',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Description
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Addons Section
                  if (addons.isNotEmpty) ...[
                    const Text(
                      'Available Add-ons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      itemCount: addons.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final addon = addons[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF6366F1),
                            ),
                            title: Text(addon['name'] ?? ''),
                            trailing: Text(
                              '₹${addon['price']}',
                              style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🔹 Book Now Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.shopping_bag),
          label: const Text(
            'Book Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ConfirmBookingScreen(serviceData: serviceData),
              ),
            );
          },
        ),
      ),
    );
  }
}

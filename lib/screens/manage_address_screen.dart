import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_edit_address_screen.dart';

class ManageAddressScreen extends StatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (doc.exists && doc['addresses'] != null) {
      addresses = List<Map<String, dynamic>>.from(doc['addresses']);
      // Sort default first
      addresses.sort(
        (a, b) => (b['isDefault'] == true ? 1 : 0).compareTo(
          a['isDefault'] == true ? 1 : 0,
        ),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _deleteAddress(String id) async {
    addresses.removeWhere((addr) => addr['id'] == id);
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'addresses': addresses,
    });
    setState(() {});
  }

  Future<void> _setDefaultAddress(String id) async {
    addresses = addresses.map((addr) {
      addr['isDefault'] = addr['id'] == id;
      return addr;
    }).toList();
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'addresses': addresses,
    });
    _loadAddresses(); // reload and sort
  }

  void _navigateToAddEdit(Map<String, dynamic>? address) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address)),
    );
    _loadAddresses(); // reload after add/edit
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Addresses')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final addr = addresses[index];
                  return GestureDetector(
                    onTap: () => _setDefaultAddress(addr['id']),
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: addr['isDefault'] == true
                            ? const BorderSide(color: Colors.green, width: 2)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  addr['type'] ?? 'Home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: addr['isDefault'] == true
                                        ? Colors.green
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (addr['isDefault'] == true)
                                  const Text(
                                    '(Default)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _navigateToAddEdit(addr),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteAddress(addr['id']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(addr['fullAddress'] ?? ''),
                            const SizedBox(height: 2),
                            Text(
                              "${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['pinCode'] ?? ''}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddEdit(null),
              icon: const Icon(Icons.add),
              label: const Text('Add New Address'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

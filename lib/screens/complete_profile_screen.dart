import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../utils/logout.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../utils/permission_handler.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, this.addressToEdit});
  final Map<String, dynamic>? addressToEdit;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  String _addressType = 'Home';

  bool _isLoading = true;
  String? _photoUrl;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  double? _latitude;
  double? _longitude;

  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      _fullNameController.text = data['displayName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _photoUrl = (data['photoUrl'] != null && data['photoUrl'].isNotEmpty)
          ? data['photoUrl']
          : "https://api.dicebear.com/7.x/bottts/png?seed=${user!.uid}";

      // Load first/default address if available
      // If editing a specific address, load it
      if (widget.addressToEdit != null) {
        final addr = widget.addressToEdit!;
        _addressController.text = addr['fullAddress'] ?? '';
        _cityController.text = addr['city'] ?? '';
        _stateController.text = addr['state'] ?? '';
        _pinCodeController.text = addr['pinCode'] ?? '';
        _addressType = addr['type'] ?? 'Home';
        _latitude = addr['latitude'] ?? 0.0;
        _longitude = addr['longitude'] ?? 0.0;
      } else if (data['addresses'] != null &&
          data['addresses'] is List &&
          (data['addresses'] as List).isNotEmpty) {
        final addresses = List<Map<String, dynamic>>.from(data['addresses']);
        // Pick the default address; fallback to first if none is default
        final defaultAddress = addresses.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => addresses[0],
        );
        _addressController.text = defaultAddress['fullAddress'] ?? '';
        _cityController.text = defaultAddress['city'] ?? '';
        _stateController.text = defaultAddress['state'] ?? '';
        _pinCodeController.text = defaultAddress['pinCode'] ?? '';
        _addressType = defaultAddress['type'] ?? 'Home';
        _latitude = defaultAddress['latitude'] ?? 0.0;
        _longitude = defaultAddress['longitude'] ?? 0.0;
      }
    } else {
      // For new users without photoUrl, generate DiceBear avatar
      _photoUrl = "https://api.dicebear.com/7.x/bottts/png?seed=${user!.uid}";
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Request location permission first
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _addressController.text = "${place.street}";
          _cityController.text = place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _pinCodeController.text = place.postalCode ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching location: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final avatarUrl =
          _photoUrl ??
          "https://api.dicebear.com/7.x/bottts/png?seed=${user!.uid}";

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);
      final snapshot = await docRef.get();

      // Load existing addresses if any
      List<Map<String, dynamic>> addresses = [];
      if (snapshot.exists && snapshot['addresses'] != null) {
        addresses = List<Map<String, dynamic>>.from(snapshot['addresses']);
      }

      // Determine address ID (new or editing)
      final addressId = widget.addressToEdit?['id'] ?? const Uuid().v4();
      final addressObj = {
        "id": addressId,
        "type": _addressType,
        "fullAddress": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "pinCode": _pinCodeController.text.trim(),
        "latitude": _latitude ?? 0.0,
        "longitude": _longitude ?? 0.0,
        // Keep isDefault true if it was already default or first address
        "isDefault": addresses.isEmpty
            ? true
            : widget.addressToEdit?['isDefault'] ?? false,
      };

      // If editing, replace the address in the list
      final index = addresses.indexWhere((a) => a['id'] == addressId);
      if (index >= 0) {
        addresses[index] = addressObj;
      } else {
        addresses.add(addressObj);
      }

      // Save user data with updated addresses
      await docRef.set({
        "displayName": _fullNameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "photoUrl": avatarUrl,
        "role": "customer",
        "updatedAt": FieldValue.serverTimestamp(),
        "addresses": addresses,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      // Navigate back to Profile screen after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: (_photoUrl == null || _photoUrl!.isEmpty)
                    ? Text(
                        _fullNameController.text.isNotEmpty
                            ? _fullNameController.text[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your phone number'
                    : null,
              ),
              const SizedBox(height: 16),
              // use current location button
              ElevatedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text("Use Current Location"),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your address'
                    : null,
              ),
              const SizedBox(height: 16),
              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your city' : null,
              ),
              const SizedBox(height: 16),
              // State
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your state' : null,
              ),
              const SizedBox(height: 16),
              // Pin Code
              TextFormField(
                controller: _pinCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pin Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your pin code'
                    : null,
              ),
              const SizedBox(height: 16),
              // Address Type
              DropdownButtonFormField<String>(
                value: _addressType,
                items: const [
                  DropdownMenuItem(value: 'Home', child: Text('Home')),
                  DropdownMenuItem(value: 'Office', child: Text('Office')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _addressType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

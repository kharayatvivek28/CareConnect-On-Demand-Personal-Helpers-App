import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../utils/permission_handler.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? address; // null for new, non-null for edit
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  String _addressType = 'Home';
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final addr = widget.address!;
      _fullAddressController.text = addr['fullAddress'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _stateController.text = addr['state'] ?? '';
      _pinCodeController.text = addr['pinCode'] ?? '';
      _addressType = addr['type'] ?? 'Home';
      _latitude = addr['latitude'] ?? 0.0;
      _longitude = addr['longitude'] ?? 0.0;
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Request location permission
      bool hasPermission =
          await requestLocationPermission(); // You can reuse your permission handler
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
          _fullAddressController.text = place.street ?? '';
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

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);
    final snapshot = await docRef.get();

    List<Map<String, dynamic>> addresses = [];
    if (snapshot.exists && snapshot['addresses'] != null) {
      addresses = List<Map<String, dynamic>>.from(snapshot['addresses']);
    }

    final addressId = widget.address?['id'] ?? const Uuid().v4();
    final newAddress = {
      "id": addressId,
      "type": _addressType,
      "fullAddress": _fullAddressController.text.trim(),
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "pinCode": _pinCodeController.text.trim(),
      "latitude": _latitude ?? 0.0,
      "longitude": _longitude ?? 0.0,
      "isDefault": addresses.isEmpty
          ? true
          : widget.address?['isDefault'] ?? false,
    };

    final index = addresses.indexWhere((a) => a['id'] == addressId);
    if (index >= 0) {
      addresses[index] = newAddress;
    } else {
      addresses.add(newAddress);
    }

    await docRef.set({'addresses': addresses}, SetOptions(merge: true));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address != null ? 'Edit Address' : 'Add Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text("Use Current Location"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullAddressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter city' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter state' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pin Code',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter pin code' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _addressType,
                items: const [
                  DropdownMenuItem(value: 'Home', child: Text('Home')),
                  DropdownMenuItem(value: 'Office', child: Text('Office')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _addressType = v!),
                decoration: const InputDecoration(
                  labelText: 'Address Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

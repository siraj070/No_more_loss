import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:file_picker/file_picker.dart';

class ShopRegistrationScreen extends StatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  File? _pickedImage;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _imageName = result.files.first.name;
        if (kIsWeb) {
          _imageBytes = result.files.first.bytes;
        } else {
          _pickedImage = File(result.files.first.path!);
        }
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Enable location services.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      Position position =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Hide door/street info for privacy
        _addressController.text =
            '${place.subLocality ?? ''}, ${place.locality ?? ''}';
        _cityController.text = place.locality ?? '';
        _pincodeController.text = place.postalCode ?? '';
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Location detected!'),
        backgroundColor: Color(0xFF10B981),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<String?> _uploadImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('shop_photos')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask uploadTask;
      if (kIsWeb && _imageBytes != null) {
        uploadTask = storageRef.putData(_imageBytes!);
      } else if (_pickedImage != null) {
        uploadTask = storageRef.putFile(_pickedImage!);
      } else {
        throw Exception('No image selected');
      }

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final photoUrl = await _uploadImage();

      await FirebaseFirestore.instance.collection('pending_shops').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'shopName': _shopNameController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'shopAddress':
            '${_addressController.text.trim()}, ${_cityController.text.trim()} - ${_pincodeController.text.trim()}',
        'shopPhotoUrl': photoUrl,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🕒 Shop submitted for admin approval!'),
        backgroundColor: Color(0xFF10B981),
      ));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Registration', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : (_imageBytes != null
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : const Center(child: Text('Tap to upload shop photo'))),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: 'Shop Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter shop name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(
                  labelText: 'GST Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter GST number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Shop Address (auto-filled via GPS)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter city' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter pincode' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _getLocation,
                icon: _isGettingLocation
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, color: Color(0xFF10B981)),
                label: const Text('Use GPS'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit for Approval'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

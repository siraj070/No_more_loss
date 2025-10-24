import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'checkout_screen.dart';

// 🔑 Paste your Google API key here ↓↓↓
const String googleApiKey ='AIzaSyBECS1PMTMEfHt201QVexNNSp7h96ozJz4';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doorController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLocating = false;

  @override
  void dispose() {
    _doorController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 📍 Auto-detect location
  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() => _isLocating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permission permanently denied')),
        );
        setState(() => _isLocating = false);
        return;
      }

      // ✅ Get current position
      // (keeping your inner logic, fixed formatting)
      Future<void> _detectLocationInner() async {
        setState(() => _isLocating = true);

        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            throw Exception('Location services are disabled.');
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.deniedForever) {
            throw Exception('Location permission permanently denied.');
          }

          // ✅ FIX: Handle null position safely for Flutter Web
          Position? position;
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best,
            ).timeout(const Duration(seconds: 10));
          } catch (_) {
            position = null;
          }

          if (position == null) {
            throw Exception('Unable to detect your location.');
          }

          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            setState(() {
              _doorController.text = place.name ?? '';
              _streetController.text = [
                place.street,
                place.subLocality,
                place.subAdministrativeArea
              ].where((e) => e != null && e!.isNotEmpty).join(', ');
              _cityController.text = place.locality ?? '';
              _pincodeController.text = place.postalCode ?? '';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Location detected successfully!')),
            );
          } else {
            // Fallback to Google Geocoding API if Flutter fails
            await _fetchFromGoogleAPI(position);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get location: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        setState(() => _isLocating = false);
      }

      // calling the inner logic
      await _detectLocationInner().catchError((e) {
        debugPrint('Error getting position: $e');
        return null;
      });

      // ✅ Try local geocoding again (kept your original flow)
      Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not get your location — please allow location access'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLocating = false);
        return;
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _doorController.text = place.name ?? '';
          _streetController.text = [
            place.street,
            place.subLocality,
            place.subAdministrativeArea
          ].where((e) => e != null && e!.isNotEmpty).join(', ');
          _cityController.text = place.locality ?? 'Unknown';
          _pincodeController.text = place.postalCode ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location detected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _fetchFromGoogleAPI(position);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _isLocating = false);
  }

  // 🌍 Fallback: Google Maps Geocoding API
  Future<void> _fetchFromGoogleAPI(Position position) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleApiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final result = data['results'][0];
        final formattedAddress = result['formatted_address'];

        // Parse address components for city and postal code
        String? city;
        String? postalCode;

        for (var component in result['address_components']) {
          final types = List<String>.from(component['types']);
          if (types.contains('locality')) {
            city = component['long_name'];
          }
          if (types.contains('postal_code')) {
            postalCode = component['long_name'];
          }
        }

        setState(() {
          _streetController.text = formattedAddress;
          _cityController.text = city ?? '';
          _pincodeController.text = postalCode ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌍 Address fetched using Google Maps API'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to fetch address details'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching data from Google Maps API'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // 🧾 Proceed to Checkout
  void _proceedToCheckout() {
    if (_formKey.currentState!.validate()) {
      final address = {
        'door': _doorController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CheckoutScreen(address: address)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Delivery Address',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please provide your delivery address',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _isLocating ? null : _detectLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, color: Colors.white),
                label: Text(
                  _isLocating ? 'Fetching Location...' : 'Detect My Location',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildField(_doorController, 'House/Flat No.', Icons.home_outlined,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildField(_streetController, 'Street Address',
                  Icons.location_on_outlined,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildField(_cityController, 'City', Icons.location_city_outlined,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildField(
                _pincodeController,
                'Pincode',
                Icons.markunread_mailbox_outlined,
                keyboard: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (v.length != 6) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(_phoneController, 'Phone Number', Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (v.length != 10) return 'Invalid';
                    return null;
                  }),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Proceed to Payment',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'checkout_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _doorController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loadingLocation = false;

  @override
  void dispose() {
    _doorController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ===== LOCATION (NULL-SAFE) =====
  Future<void> _detectLocation() async {
    setState(() => _loadingLocation = true);
    try {
      // 1) Services
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // 2) Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      // 3) Position
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {
        throw Exception('Unable to fetch GPS location.');
      }

      // 4) Reverse geocode
      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      } catch (_) {
        throw Exception('Unable to get address from coordinates.');
      }
      if (placemarks.isEmpty) {
        throw Exception('No placemark data found.');
      }

      // 5) Fill fields safely
      final p = placemarks.first;
      final street = [
        if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      ].join(', ');

      setState(() {
        if (street.isNotEmpty) _streetController.text = street;
        if ((p.locality ?? '').isNotEmpty) _cityController.text = p.locality!;
        if ((p.postalCode ?? '').isNotEmpty) _pincodeController.text = p.postalCode!;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Location detected successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // ====== UI HELPERS ======
  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.2),
      ),
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: _inputDeco(label, icon),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ====== BUILD ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Add Delivery Address',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Intro
                  Text(
                    'Please provide accurate delivery details. You can also auto-detect your location.',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address Card
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('Address'),
                        const SizedBox(height: 14),
                        _field(
                          controller: _doorController,
                          label: 'Door / Flat No.',
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _streetController,
                          label: 'Street / Area',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                controller: _cityController,
                                label: 'City',
                                icon: Icons.location_city_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                controller: _pincodeController,
                                label: 'Pincode',
                                icon: Icons.pin_drop_outlined,
                                type: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter Pincode';
                                  }
                                  if (v.trim().length < 4) {
                                    return 'Invalid Pincode';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_android_outlined,
                          type: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter Phone Number';
                            }
                            if (v.trim().length < 7) {
                              return 'Invalid Phone Number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadingLocation ? null : _detectLocation,
                          icon: _loadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_outlined,
                                  color: Colors.white),
                          label: Text(
                            _loadingLocation ? 'Detecting…' : 'Use My Location',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tips / Notes (optional, keeps length & UX)
                  _card(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tip: If location permission was denied earlier, enable it in your browser/app settings and try again. '
                            'You can always edit your address on the next screen before paying.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Continue Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final addressMap = {
                            'door': _doorController.text.trim(),
                            'street': _streetController.text.trim(),
                            'city': _cityController.text.trim(),
                            'pincode': _pincodeController.text.trim(),
                            'phone': _phoneController.text.trim(),
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(address: addressMap),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Continue to Checkout',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'You can review & edit on the next screen.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

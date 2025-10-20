import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullAddressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoadingLocation = false;
  bool _isPlacingOrder = false;
  String _selectedPaymentMethod = 'Cash on Delivery';

  double? _latitude;
  double? _longitude;

  final List<String> paymentMethods = [
    'Cash on Delivery',
    'UPI',
    'Card',
    'Wallet',
  ];

  // Location detection function with error handling and address autofill
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location in your device settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please allow location access.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable permissions in app settings.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      _latitude = position.latitude;
      _longitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _fullAddressController.text = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}'.trim();
          _cityController.text = place.locality ?? '';
          _pincodeController.text = place.postalCode ?? '';
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location detected successfully! ✅'),
        backgroundColor: Color(0xFF10B981),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
      ));
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final cartService = Provider.of<CartService>(context, listen: false);

      final addressString =
          '${_fullAddressController.text}, ${_landmarkController.text}, ${_cityController.text} - ${_pincodeController.text}, Phone: ${_phoneController.text}';

      final order = AppOrder(
        id: '',
        customerId: user!.uid,
        items: List.from(cartService.items),
        totalAmount: cartService.totalAmount,
        address: addressString,
        createdAt: Timestamp.now(),
      );

      await OrderService().addOrder(order);
      cartService.clearCart();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🎉 Order placed successfully!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to place order: ${e.toString()}'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Items (${cartService.itemCount})', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      Text('₹${cartService.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery Fee', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      Text('FREE', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('₹${cartService.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),

            // Delivery Address Section with "Use GPS" Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery Address',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('Use GPS'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),

            // Address Form Fields
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fullAddressController,
                      decoration: InputDecoration(
                        labelText: 'Full Address *',
                        hintText: 'House No, Building, Street',
                        prefixIcon: const Icon(Icons.home, color: Color(0xFF10B981)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Landmark',
                        hintText: 'Near famous place',
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF10B981)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: 'City *',
                              prefixIcon: const Icon(Icons.location_city, color: Color(0xFF10B981)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            decoration: InputDecoration(
                              labelText: 'Pincode *',
                              prefixIcon: const Icon(Icons.pin_drop, color: Color(0xFF10B981)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '10-digit mobile number',
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF10B981)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (v.length != 10) return 'Must be 10 digits';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Payment Method', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ...paymentMethods.map((method) {
              return RadioListTile<String>(
                title: Text(method, style: GoogleFonts.poppins()),
                value: method,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                activeColor: const Color(0xFF10B981),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isPlacingOrder
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Place Order - ₹${cartService.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/cart_service.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../web_razorpay_service.dart' if (dart.library.html) '../web_razorpay_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullAddressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  late Razorpay _razorpay;
  bool _isLoadingLocation = false;
  bool _isPlacingOrder = false;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  /// 🗺️ Get Current Location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Please enable location services.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission permanently denied. Enable in settings.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _fullAddressController.text =
            '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}';
        _cityController.text = place.locality ?? '';
        _pincodeController.text = place.postalCode ?? '';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location detected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// 💳 Open Razorpay Checkout
  void _openCheckout(double amount) async {
    if (kIsWeb) {
      // For Web
      try {
        RazorpayWeb.openCheckout(
          key: 'rzp_test_RVn4gcgHMRXP8s',
          amount: amount,
          name: 'No More Loss',
          description: 'Order Payment',
          contact: _phoneController.text.isNotEmpty
              ? _phoneController.text
              : '9999999999',
          email: 'test@example.com',
        );
      } catch (e) {
        debugPrint('Web Razorpay Error: $e');
      }
    } else {
      // For Mobile (Android/iOS)
      var options = {
        'key': 'rzp_test_RVn4gcgHMRXP8s',
        'amount': (amount * 100).toInt(),
        'name': 'No More Loss',
        'description': 'Order Payment',
        'prefill': {'contact': _phoneController.text, 'email': 'user@test.com'},
        'theme.color': '#10B981',
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Mobile Razorpay Error: $e');
      }
    }
  }

  /// ✅ Payment Success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Payment Successful: ${response.paymentId}')),
    );
    await _saveOrder(response.paymentId ?? '');
  }

  /// ❌ Payment Failure
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '❌ Payment Failed: ${response.code} | ${response.message ?? "Unknown error"}'),
      ),
    );
  }

  /// 💼 External Wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet: ${response.walletName}')),
    );
  }

  /// 🧾 Save Order with Payment Info
  Future<void> _saveOrder(String paymentId) async {
    setState(() => _isPlacingOrder = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final cartService = Provider.of<CartService>(context, listen: false);

      final address =
          '${_fullAddressController.text}, ${_landmarkController.text}, ${_cityController.text} - ${_pincodeController.text}, Phone: ${_phoneController.text}';

      final orderData = {
        'customerId': user!.uid,
        'items': cartService.items.map((item) {
          return {
            'productId': item.product.id,
            'name': item.product.name,
            'price': item.product.discountedPrice,
            'quantity': item.quantity,
            'totalPrice': item.totalPrice,
          };
        }).toList(),
        'totalAmount': cartService.totalAmount,
        'address': address,
        'paymentId': paymentId,
        'status': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);
      cartService.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Payment successful & order saved!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving order: ${e.toString()}')),
      );
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ₹${cartService.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openCheckout(cartService.totalAmount),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}

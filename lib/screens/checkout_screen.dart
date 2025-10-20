import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/cart_service.dart';
import '../web_razorpay_service.dart' if (dart.library.html) '../web_razorpay_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, String>? address; // coming from AddressScreen

  const CheckoutScreen({super.key, this.address});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Razorpay _razorpay;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // --- UI helpers ---
  Widget _priceRow(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: bold ? Colors.black : Colors.grey.shade700,
            )),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? const Color(0xFF10B981) : Colors.black,
          ),
        ),
      ],
    );
  }

  // --- Payments ---
  void _payNow(double grandTotal) {
    if (kIsWeb) {
      try {
        RazorpayWeb.openCheckout(
          key: 'rzp_test_RVn4gcgHMRXP8s',
          amount: grandTotal,
          name: 'No More Loss',
          description: 'Order Payment',
          contact: widget.address?['phone'] ?? '9999999999',
          email: 'test@example.com',
        );
      } catch (e) {
        debugPrint('Web Razorpay Error: $e');
      }
    } else {
      final options = {
        'key': 'rzp_test_RVn4gcgHMRXP8s',
        'amount': (grandTotal * 100).toInt(),
        'name': 'No More Loss',
        'description': 'Order Payment',
        'prefill': {
          'contact': widget.address?['phone'] ?? '9999999999',
          'email': 'user@test.com'
        },
        'theme.color': '#10B981',
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Mobile Razorpay Error: $e');
      }
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Payment Successful: ${response.paymentId}')),
    );
    await _saveOrder(paymentId: response.paymentId ?? '');
  }

  void _onPaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '❌ Payment Failed: ${response.code} | ${response.message ?? "Unknown"}')),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet: ${response.walletName}')),
    );
  }

  Future<void> _saveOrder({required String paymentId}) async {
    setState(() => _isPlacingOrder = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }
      final cartService = Provider.of<CartService>(context, listen: false);

      // Pricing
      final subtotal = cartService.totalAmount;
      final tax = double.parse((subtotal * 0.05).toStringAsFixed(2)); // 5%
      const delivery = 30.0; // flat for now
      final grandTotal = double.parse((subtotal + tax + delivery).toStringAsFixed(2));

      // Address string
      final addr = widget.address ?? {};
      final addressString =
          '${addr['door'] ?? ''}, ${addr['street'] ?? ''}, ${addr['city'] ?? ''} - ${addr['pincode'] ?? ''}\nPhone: ${addr['phone'] ?? ''}';

      // Build order payload
      final items = cartService.items
          .map((item) => {
                'productId': item.product.id,
                'name': item.product.name,
                'price': item.product.discountedPrice,
                'quantity': item.quantity,
                'totalPrice': item.totalPrice,
              })
          .toList();

      final data = {
        'customerId': user.uid,
        'items': items,
        'pricing': {
          'subtotal': subtotal,
          'tax': tax,
          'delivery': delivery,
          'grandTotal': grandTotal,
        },
        'address': addr,
        'addressString': addressString,
        'paymentId': paymentId,
        'status': 'ordered',
        'statusHistory': [
          {'status': 'ordered', 'at': FieldValue.serverTimestamp()}
        ],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(data);

      cartService.clearCart();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _OrderSuccessScreen()),
        );
      }
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
    final subtotal = cartService.totalAmount;
    final tax = double.parse((subtotal * 0.05).toStringAsFixed(2)); // 5%
    const delivery = 30.0;
    final grandTotal = double.parse((subtotal + tax + delivery).toStringAsFixed(2));

    final addr = widget.address ?? {};
    final addressLines = [
      if ((addr['door'] ?? '').isNotEmpty) addr['door'],
      if ((addr['street'] ?? '').isNotEmpty) addr['street'],
      if (((addr['city'] ?? '').isNotEmpty) || ((addr['pincode'] ?? '').isNotEmpty))
        '${addr['city'] ?? ''} - ${addr['pincode'] ?? ''}',
      if ((addr['phone'] ?? '').isNotEmpty) '📞 ${addr['phone']}',
    ].where((e) => e != null && e!.trim().isNotEmpty).cast<String>().toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Address Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery Address',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(
                              addressLines.isEmpty
                                  ? 'No address provided'
                                  : addressLines.join('\n'),
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context), // go back to edit
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Items + Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Items
                      ...cartService.items.map((i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  i.product.name,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text('x${i.quantity}',
                                  style: GoogleFonts.poppins(color: Colors.grey[600])),
                              const SizedBox(width: 10),
                              Text('₹${i.totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 24),
                      _priceRow('Subtotal', subtotal),
                      const SizedBox(height: 6),
                      _priceRow('Tax (5%)', tax),
                      const SizedBox(height: 6),
                      _priceRow('Delivery', delivery),
                      const SizedBox(height: 10),
                      _priceRow('Grand Total', grandTotal, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Little poem / brand line
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '“No More Loss” — we pack with care, we deliver with pace; '
                    'from your cart to your door, a smile on your face. ✨',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF065F46)),
                  ),
                ),
                const SizedBox(height: 16),

                // Pay button
                ElevatedButton(
                  onPressed: _isPlacingOrder ? null : () => _payNow(grandTotal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isPlacingOrder ? 'Placing Order...' : 'Pay ₹${grandTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderSuccessScreen extends StatelessWidget {
  const _OrderSuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Order Placed', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text('Thank you!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Your order has been placed successfully.',
                style: GoogleFonts.poppins(color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to My Orders'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- My Orders Screen ----------------

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Color _statusColor(String s) {
    switch (s) {
      case 'ordered':
        return const Color(0xFF2563EB);
      case 'picked':
        return const Color(0xFFF59E0B);
      case 'delivered':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  int _statusIndex(String s) {
    switch (s) {
      case 'ordered':
        return 0;
      case 'picked':
        return 1;
      case 'delivered':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
      ),
      body: uid == null
          ? Center(child: Text('Please sign in', style: GoogleFonts.poppins()))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No orders yet', style: GoogleFonts.poppins()),
                  );
                }
                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final status = (d['status'] ?? 'ordered') as String;
                    final pricing = (d['pricing'] ?? {}) as Map<String, dynamic>;
                    final items = (d['items'] ?? []) as List;
                    final addressString = (d['addressString'] ?? '') as String;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600, fontSize: 16)),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // items summary (first item)
                          if (items.isNotEmpty)
                            Text(
                              '${items[0]['name']}'
                              '${items.length > 1 ? ' + ${items.length - 1} more' : ''}',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),

                          // address
                          if (addressString.isNotEmpty)
                            Text(
                              addressString,
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                            ),

                          const SizedBox(height: 12),
                          // price + steps
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${(pricing['grandTotal'] ?? 0).toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              // step indicator
                              Row(
                                children: List.generate(3, (idx) {
                                  final active = idx <= _statusIndex(status);
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? _statusColor(status)
                                          : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

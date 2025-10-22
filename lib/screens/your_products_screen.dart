import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class YourProductsScreen extends StatefulWidget {
  const YourProductsScreen({super.key});

  @override
  State<YourProductsScreen> createState() => _YourProductsScreenState();
}

class _YourProductsScreenState extends State<YourProductsScreen> {
  final ProductService _productService = ProductService();
  String? _ownerUID;
  Set<String> _soldProductIds = {};
  bool _loading = true;
  late final FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _initializeData();

    // ✅ Failsafe listener — triggers reload if user changes or Firebase reauths
    _auth.authStateChanges().listen((user) async {
      if (user != null && user.uid != _ownerUID) {
        await _reloadUID(user.uid);
      }
    });
  }

  Future<void> _reloadUID(String newUID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopOwnerUID', newUID);
    await _loadData(newUID);
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUID = _auth.currentUser?.uid;

    // ✅ If logged in, store UID for persistence
    if (currentUID != null) {
      await prefs.setString('shopOwnerUID', currentUID);
    }

    final savedUID = prefs.getString('shopOwnerUID');
    final ownerUID = currentUID ?? savedUID;

    if (ownerUID != null) {
      await _loadData(ownerUID);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadData(String ownerUID) async {
    try {
      // ✅ Fetch sold product IDs (batch query)
      final orders = await FirebaseFirestore.instance
          .collection('orders')
          .where('ownerId', isEqualTo: ownerUID)
          .get();

      final soldIds =
          orders.docs.map((doc) => doc['productId'] as String).toSet();

      setState(() {
        _ownerUID = ownerUID;
        _soldProductIds = soldIds;
        _loading = false;
      });

      // Debug confirmation
      // ignore: avoid_print
      print('✅ Loaded UID: $_ownerUID — Sold products: ${_soldProductIds.length}');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Error loading products: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ownerUID == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        title: Text(
          'Your Products',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _ownerUID != null
            ? _productService.getProductsByOwner(_ownerUID!)
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 100, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'You haven’t uploaded any products yet.',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final isSold = _soldProductIds.contains(product.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  leading: product.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                        )
                      : const Icon(Icons.local_grocery_store,
                          color: Color(0xFF10B981), size: 40),
                  title: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.discountedPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            color: Colors.black87, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSold
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isSold ? 'Sold' : 'Available',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSold ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

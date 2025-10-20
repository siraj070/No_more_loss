import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ShopOwnerProfileScreen extends StatelessWidget {
  final String ownerId;

  const ShopOwnerProfileScreen({super.key, required this.ownerId});

  Future<Map<String, dynamic>?> _fetchOwnerData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    final ProductService productService = ProductService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Owner Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchOwnerData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Owner data not found', style: GoogleFonts.poppins(fontSize: 16)));
          }

          final ownerData = snapshot.data!;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: const Color(0xFF10B981),
                width: double.infinity,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.storefront, size: 60, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ownerData['displayName'] ?? 'Shop Owner',
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerData['email'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    // You can add more owner info, social links etc here
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: productService.getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No products added yet', style: GoogleFonts.poppins(fontSize: 16)));
                    }

                    final products = snapshot.data!
                        .where((product) => product.ownerId == ownerId)
                        .toList();

                    if (products.isEmpty) {
                      return Center(child: Text('No products by this owner yet', style: GoogleFonts.poppins(fontSize: 16)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: ListTile(
                            title: Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            subtitle: Text('₹${product.discountedPrice.toStringAsFixed(0)}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

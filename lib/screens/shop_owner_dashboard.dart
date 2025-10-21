import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'add_product_screen.dart';
import 'shop_registration_screen.dart';
import '../utils/slide_transition.dart';
import 'settings/shop_owner_settings.dart';

class ShopOwnerDashboard extends StatefulWidget {
  const ShopOwnerDashboard({super.key});

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  final ProductService _productService = ProductService();
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.red),
    );
  }

  void _navigateToAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    setState(() {});
  }

  void _navigateToEditProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
    );
    setState(() {});
  }

  void _navigateToShopRegistration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Shop Owner Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                  SlideRightRoute(page: const ShopOwnerSettingsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Product',
            onPressed: _navigateToAddProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _navigateToShopRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.store),
              label: const Text('Register / Update Shop Info'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.getProductsByOwner(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store_mall_directory_outlined,
                            size: 100, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No products added yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey,
                            )),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        leading: product.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(product.imageUrl,
                                    width: 50, height: 50, fit: BoxFit.cover),
                              )
                            : const Icon(
                                Icons.local_grocery_store,
                                color: Color(0xFF10B981),
                              ),
                        title: Text(product.name,
                            style:
                                GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle:
                            Text('₹${product.discountedPrice.toStringAsFixed(0)}'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToEditProduct(product);
                            } else {
                              _deleteProduct(product.id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

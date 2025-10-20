import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';            // ← Added
import 'add_product_screen.dart';
import 'order_history_screen.dart';                  // ← Added

class ShopOwnerDashboard extends StatefulWidget {
  @override
  _ShopOwnerDashboardState createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  final ProductService _productService = ProductService();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product deleted'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Owner Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFF10B981),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddProductScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // My Orders button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderHistoryScreen()),
                );
              },
              icon: Icon(Icons.history, color: Colors.white),
              label: Text(
                'My Orders',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),

            // Product list
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.isEmpty)
                    return Center(child: Text('No products added yet', style: GoogleFonts.poppins(fontSize: 16)));

                  final products = snapshot.data!
                      .where((product) => product.ownerId == user?.uid)
                      .toList();

                  if (products.isEmpty)
                    return Center(child: Text('No products added by you yet', style: GoogleFonts.poppins(fontSize: 16)));

                  return ListView.builder(
                    padding: EdgeInsets.only(top: 0),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: ListTile(
                          leading: Icon(Icons.local_grocery_store, color: Color(0xFF10B981)),
                          title: Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text('₹${product.discountedPrice.toStringAsFixed(0)}'),
                          trailing: PopupMenuButton(
                            icon: Icon(Icons.more_vert),
                            itemBuilder: (ctx) => [
                              PopupMenuItem(child: Text('Edit'), value: 'edit'),
                              PopupMenuItem(child: Text('Delete', style: TextStyle(color: Colors.red)), value: 'delete'),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
                                ).then((_) => setState(() {}));
                              } else if (value == 'delete') {
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
      ),
    );
  }
}

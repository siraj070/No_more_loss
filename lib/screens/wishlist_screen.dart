import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('My Wishlist',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: StreamBuilder<List<Product>>(
        stream: productService.getWishlistProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 100, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Your wishlist is empty',
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey)),
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
              final daysLeft =
                  product.expiryDate.difference(DateTime.now()).inDays;
              final isExpired = product.expiryDate.isBefore(DateTime.now());

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 65,
                            height: 65,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_outlined,
                                color: Colors.grey),
                          ),
                  ),
                  title: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${product.discountedPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        isExpired
                            ? 'Expired'
                            : daysLeft <= 3
                                ? '$daysLeft days left'
                                : 'Exp: ${product.expiryDate.toLocal().toString().split(' ')[0]}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isExpired
                                ? Colors.red
                                : daysLeft <= 3
                                    ? Colors.orange
                                    : Colors.grey[700]),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => productService.toggleWishlist(product.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

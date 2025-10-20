import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    final daysLeft = product.expiryDate.difference(DateTime.now()).inDays;
    final discountPercent =
        ((product.originalPrice - product.discountedPrice) / product.originalPrice * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFF10B981),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(Icons.local_grocery_store, size: 100, color: Color(0xFF10B981)),
                      ),
                    ),
            ),
            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$discountPercent% OFF',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Text(
                  '₹${product.discountedPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '₹${product.originalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Chip(
                  label: Text(product.category),
                  backgroundColor: Color(0xFF10B981).withOpacity(0.15),
                  labelStyle: GoogleFonts.poppins(color: Color(0xFF10B981)),
                ),
                SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: daysLeft <= 3 ? Color(0xFFEF4444).withOpacity(0.15) : Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    daysLeft <= 3 ? '$daysLeft days left' : 'Exp: ${product.expiryDate.toLocal().toString().split(' ')[0]}',
                    style: GoogleFonts.poppins(
                      color: daysLeft <= 3 ? Color(0xFFEF4444) : Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            Text(
              'Near expiry product with great discount. Hurry up to save your money and avoid food wastage!',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),

            Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  cartService.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to cart!'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(Icons.shopping_cart),
                label: Text('Add to Cart', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isCustomer;

  const ProductCard({super.key, 
    required this.product,
    required this.isCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = product.expiryDate.difference(DateTime.now()).inDays;
    final discountPercent =
        ((product.originalPrice - product.discountedPrice) / product.originalPrice * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: () {
        if (isCustomer) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.local_grocery_store, size: 50, color: Color(0xFF10B981)),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '₹${product.discountedPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${product.originalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(product.category),
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: daysLeft <= 3 ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      daysLeft <= 3 ? '$daysLeft days left' : 'Exp: ${product.expiryDate.toLocal().toString().split(' ')[0]}',
                      style: GoogleFonts.poppins(
                        color: daysLeft <= 3 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

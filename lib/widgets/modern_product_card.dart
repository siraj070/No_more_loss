
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../models/product.dart';

/// A modern product card with image, name, price, and expiry badge.
/// Drop-in replacement for your list/grid tiles.
class ModernProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ModernProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDecorations.radiusLg,
      child: Container(
        decoration: AppDecorations.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16/10,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : Container(color: AppColors.bg, child: const Center(child: Icon(Icons.image, size: 36, color: AppColors.textMuted))),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('₹${product.price.toStringAsFixed(2)}', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ExpiryBadge(expiryDate: product.expiryDate),
                      const Spacer(),
                      const Icon(Icons.add_shopping_cart, size: 20, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final DateTime? expiryDate;
  const _ExpiryBadge({required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label = 'No expiry';
    Color bg = AppColors.bg;
    Color fg = AppColors.textMuted;

    if (expiryDate != null) {
      final diff = expiryDate!.difference(now).inDays;
      if (diff < 0) {
        label = 'Expired';
        bg = AppColors.error.withOpacity(0.12);
        fg = AppColors.error;
      } else if (diff <= 2) {
        label = 'Expires in ${diff}d';
        bg = AppColors.warning.withOpacity(0.12);
        fg = AppColors.warning;
      } else {
        label = 'Expires in ${diff}d';
        bg = AppColors.primary.withOpacity(0.12);
        fg = AppColors.primaryDark;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

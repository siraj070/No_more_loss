
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating; // 0..5
  final int count;
  final double size;

  const RatingStars({super.key, required this.rating, this.count = 5, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final filled = i < rating.floor();
        final half = i == rating.floor() && rating % 1 >= 0.5;
        IconData icon = filled ? Icons.star : (half ? Icons.star_half : Icons.star_border);
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(icon, color: AppColors.accent, size: size),
        );
      }),
    );
  }
}

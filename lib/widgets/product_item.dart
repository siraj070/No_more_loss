import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductItem extends StatelessWidget {
  final Product product;

  const ProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final daysLeft = product.expiryDate.difference(DateTime.now()).inDays;
    final discountPercent =
        ((product.originalPrice - product.discountedPrice) / product.originalPrice * 100)
            .toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: daysLeft <= 3 ? Colors.red : Colors.orange,
          child: Text(
            '$daysLeft',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${product.category}'),
            Text('Expires in $daysLeft days'),
            Text(
              '₹${product.originalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${product.discountedPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              '$discountPercent% OFF',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

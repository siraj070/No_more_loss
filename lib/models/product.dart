import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double originalPrice;
  final double discountedPrice;
  final int quantity;
  final String imageUrl;
  final String ownerId;
  final DateTime expiryDate;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.imageUrl,
    required this.ownerId,
    required this.expiryDate,
  });

  // Backward compatibility
  double get price => discountedPrice;

  /// ✅ Handles both Timestamp and String expiryDate types safely
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime expiry;

    final rawDate = data['expiryDate'];

    if (rawDate is Timestamp) {
      expiry = rawDate.toDate();
    } else if (rawDate is String) {
      try {
        expiry = DateTime.parse(rawDate);
      } catch (_) {
        expiry = DateTime.now();
      }
    } else {
      expiry = DateTime.now();
    }

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (data['discountedPrice'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      expiryDate: expiry,
    );
  }

  /// ✅ Always saves as a Firestore Timestamp going forward
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'expiryDate': Timestamp.fromDate(expiryDate),
    };
  }
}

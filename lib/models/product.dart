import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double originalPrice;
  final double discountedPrice;
  final DateTime expiryDate;
  final String ownerId;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.expiryDate,
    required this.ownerId,
    this.imageUrl = '',  // Made optional with default empty string
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (data['discountedPrice'] ?? 0).toDouble(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      ownerId: data['ownerId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'ownerId': ownerId,
      'imageUrl': imageUrl,
    };
  }
}


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

  /// ✅ Convert Firestore Document → Product
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Others',
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (data['discountedPrice'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      expiryDate: data['expiryDate'] is Timestamp
          ? (data['expiryDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['expiryDate'].toString()) ?? DateTime.now(),
    );
  }

  /// ✅ Convert Map → Product (used in Cart)
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Others',
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (map['discountedPrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      imageUrl: map['imageUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      expiryDate: map['expiryDate'] is String
          ? DateTime.tryParse(map['expiryDate']) ?? DateTime.now()
          : map['expiryDate'] is Timestamp
              ? (map['expiryDate'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  /// ✅ Convert Product → Firestore Map
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'ownerId': ownerId,
        'expiryDate': expiryDate.toIso8601String(),
      };

  /// ✅ Convert Product → Map (used in Cart)
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'ownerId': ownerId,
        'expiryDate': expiryDate.toIso8601String(),
      };
}

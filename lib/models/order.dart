import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class AppOrder {
  final String id;
  final String customerId;
  final List<CartItem> items;
  final double totalAmount;
  final String address;
  final Timestamp createdAt;
  final String status; // NEW: 'pending', 'confirmed', 'delivered'
  final Timestamp? confirmedAt; // NEW
  final Timestamp? deliveredAt; // NEW

  AppOrder({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.createdAt,
    this.status = 'pending',
    this.confirmedAt,
    this.deliveredAt,
  });

  factory AppOrder.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AppOrder(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromMap(item))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
      confirmedAt: data['confirmedAt'],
      deliveredAt: data['deliveredAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'address': address,
      'createdAt': createdAt,
      'status': status,
      'confirmedAt': confirmedAt,
      'deliveredAt': deliveredAt,
    };
  }
}

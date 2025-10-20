import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add order
  Future<void> addOrder(AppOrder order) async {
    await _firestore.collection('orders').add(order.toMap());
  }

  // Get orders for a customer (real-time stream)
  Stream<List<AppOrder>> getCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppOrder.fromFirestore(doc)).toList());
  }

  // Update order status (for shop owner)
  Future<void> updateOrderStatus(String orderId, String status) async {
    Map<String, dynamic> updateData = {'status': status};
    
    if (status == 'confirmed') {
      updateData['confirmedAt'] = Timestamp.now();
    } else if (status == 'delivered') {
      updateData['deliveredAt'] = Timestamp.now();
    }
    
    await _firestore.collection('orders').doc(orderId).update(updateData);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Get all products (customer sees all, shop owner sees own)
  Stream<List<Product>> getAllProducts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    final userId = currentUser.uid;

    // Determine if this user is shop owner or not (via Firestore users collection)
    final userDocRef = _firestore.collection('users').doc(userId);

    return userDocRef.snapshots().asyncExpand((userDoc) {
      final role = userDoc.data()?['role'] ?? 'Customer';
      Query query = _firestore.collection('products');

      if (role == 'Shop Owner') {
        // shop owners → see only their own
        query = query.where('ownerId', isEqualTo: userId);
      } else {
        // customers → see all non-expired products
        query = query.where('expiryDate',
            isGreaterThan: Timestamp.fromDate(DateTime.now()));
      }

      return query.orderBy('expiryDate').snapshots().map(
          (snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
    });
  }

  /// ✅ Get products by owner
  Stream<List<Product>> getProductsByOwner(String ownerId) {
    return _firestore
        .collection('products')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// ✅ Get products by category (handles customer/shop)
  Stream<List<Product>> getProductsByCategory(String category) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    final userId = currentUser.uid;
    final userDocRef = _firestore.collection('users').doc(userId);

    return userDocRef.snapshots().asyncExpand((userDoc) {
      final role = userDoc.data()?['role'] ?? 'Customer';
      Query query = _firestore
          .collection('products')
          .where('category', isEqualTo: category);

      if (role == 'Shop Owner') {
        query = query.where('ownerId', isEqualTo: userId);
      } else {
        query = query.where('expiryDate',
            isGreaterThan: Timestamp.fromDate(DateTime.now()));
      }

      return query.orderBy('expiryDate').snapshots().map(
          (snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
    });
  }

  /// Add product
  Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toMap());
    notifyListeners();
  }

  /// Update product
  Future<void> updateProduct(Product product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toMap());
    notifyListeners();
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    notifyListeners();
  }
}

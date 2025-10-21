import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all products
  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection('products')
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // Get products by owner
  Stream<List<Product>> getProductsByOwner(String ownerId) {
    return _firestore
        .collection('products')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // Add product
  Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toMap());
    notifyListeners();
  }

  // Update product
  Future<void> updateProduct(Product product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toMap());
    notifyListeners();
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    notifyListeners();
  }
}

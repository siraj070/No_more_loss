import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference _products =
      FirebaseFirestore.instance.collection('products');

  /// ✅ Add product
  Future<void> addProduct(Product product) async {
    await _products.add({
      ...product.toJson(),
      'createdAt': Timestamp.now(), // required for sorting & visibility
    });
  }

  /// ✅ Get all products (for customers)
  Stream<List<Product>> getProducts() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// ✅ Get products for a specific shop owner
  Stream<List<Product>> getProductsByOwner(String ownerId) {
    return _products
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// ✅ Update existing product
  Future<void> updateProduct(Product product) async {
    await _products.doc(product.id).update(product.toJson());
  }

  /// ✅ Delete a product
  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }
}

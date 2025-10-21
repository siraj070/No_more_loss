import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final CollectionReference _productCollection =
      FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> getProducts() {
    return _productCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> addProduct(Product product) async {
    await _productCollection.add(product.toMap());
    notifyListeners();
  }

  Future<void> updateProduct(String id, Product updatedProduct) async {
    await _productCollection.doc(id).update(updatedProduct.toMap());
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _productCollection.doc(id).delete();
    notifyListeners();
  }
}

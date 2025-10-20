import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference productsCollection = FirebaseFirestore.instance.collection('products');

  Future<void> addProduct(Product product) async {
    await productsCollection.add(product.toJson());
  }

  Future<void> updateProduct(Product product) async {
    await productsCollection.doc(product.id).update(product.toJson());
  }

  Stream<List<Product>> getProducts() {
    return productsCollection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }
}

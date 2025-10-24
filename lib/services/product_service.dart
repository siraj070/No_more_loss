import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime get _now => DateTime.now();

  double _discountPct(Product p) {
    if (p.originalPrice <= 0) return 0;
    return ((p.originalPrice - p.discountedPrice) / p.originalPrice) * 100.0;
  }

  /// ---------- Public Catalog Streams ----------

  Stream<List<Product>> getAllProducts() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      final query = _firestore
          .collection('products')
          .where('expiryDate', isGreaterThan: Timestamp.fromDate(_now))
          .orderBy('expiryDate');

      return query.snapshots().map(
          (s) => s.docs.map((doc) => Product.fromFirestore(doc)).toList());
    }

    final userId = currentUser.uid;
    final userDocRef = _firestore.collection('users').doc(userId);

    return userDocRef.snapshots().asyncExpand((userDoc) {
      final role = userDoc.data()?['role'] ?? 'Customer';
      Query query = _firestore.collection('products');

      if (role == 'Shop Owner') {
        query = query.where('ownerId', isEqualTo: userId);
      } else {
        query = query.where('expiryDate',
            isGreaterThan: Timestamp.fromDate(_now));
      }

      return query.orderBy('expiryDate').snapshots().map(
          (s) => s.docs.map((doc) => Product.fromFirestore(doc)).toList());
    });
  }

  Stream<List<Product>> getProductsByOwner(String ownerId) {
    return _firestore
        .collection('products')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('expiryDate')
        .snapshots()
        .map((s) => s.docs.map(Product.fromFirestore).toList());
  }

  /// ✅ FIXED: Get products by category with safe fallback for missing Firestore index
  Stream<List<Product>> getProductsByCategory(String category) {
    final currentUser = _auth.currentUser;

    // Guests/customers
    if (currentUser == null) {
      final q = _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('expiryDate', isGreaterThan: Timestamp.fromDate(_now))
          .orderBy('expiryDate');

      return q.snapshots().handleError((error) {
        if (error.toString().contains('requires an index')) {
          debugPrint(
              '⚠️ Firestore index missing for getProductsByCategory("$category").');
          debugPrint(
              '👉 Open the link shown in the console to create the composite index.');
        }
      }).map((s) => s.docs.map((doc) => Product.fromFirestore(doc)).toList());
    }

    // Logged-in users
    final userId = currentUser.uid;
    final userDocRef = _firestore.collection('users').doc(userId);

    return userDocRef.snapshots().asyncExpand((userDoc) {
      final role = userDoc.data()?['role'] ?? 'Customer';
      Query query =
          _firestore.collection('products').where('category', isEqualTo: category);

      if (role == 'Shop Owner') {
        query = query.where('ownerId', isEqualTo: userId);
      } else {
        query = query.where('expiryDate',
            isGreaterThan: Timestamp.fromDate(_now));
      }

      return query.orderBy('expiryDate').snapshots().handleError((error) {
        if (error.toString().contains('requires an index')) {
          debugPrint(
              '⚠️ Firestore index missing for category "$category" + expiryDate.');
          debugPrint(
              '👉 Copy and open the link below in your browser to create the index.');
        }
      }).map((s) => s.docs.map((doc) => Product.fromFirestore(doc)).toList());
    });
  }

  /// ---------- Search ----------
  Stream<List<Product>> searchProducts({
    required String queryText,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minDiscountPercent,
    bool expiringSoon = false,
    int serverLimit = 50,
  }) {
    final q = queryText.trim();
    Query base = _firestore.collection('products');
    base = base.where('expiryDate', isGreaterThan: Timestamp.fromDate(_now));

    if (category != null && category.isNotEmpty && category != 'All') {
      base = base.where('category', isEqualTo: category);
    }

    if (q.isNotEmpty) {
      base = base.orderBy('name').startAt([q]).endAt(['$q\uf8ff']);
    } else {
      base = base.orderBy('expiryDate');
    }

    base = base.limit(serverLimit);

    return base.snapshots().map((snap) {
      var items = snap.docs.map(Product.fromFirestore).toList();

      if (minPrice != null) {
        items = items.where((p) => p.discountedPrice >= minPrice).toList();
      }
      if (maxPrice != null) {
        items = items.where((p) => p.discountedPrice <= maxPrice).toList();
      }
      if (minDiscountPercent != null) {
        items = items.where((p) => _discountPct(p) >= minDiscountPercent).toList();
      }
      if (expiringSoon) {
        final until = _now.add(const Duration(days: 3));
        items = items.where((p) => p.expiryDate.isBefore(until)).toList();
      }

      return items;
    });
  }

  Stream<List<Product>> getSimilarProducts({
    required String category,
    required String excludeProductId,
    int withinDays = 5,
    int limit = 8,
  }) {
    final until = _now.add(Duration(days: withinDays));

    final q = _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('expiryDate', isGreaterThan: Timestamp.fromDate(_now))
        .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(until))
        .orderBy('expiryDate')
        .limit(limit);

    return q.snapshots().map((snap) {
      final list = snap.docs.map(Product.fromFirestore).toList();
      return list.where((p) => p.id != excludeProductId).toList();
    });
  }

  /// ---------- Wishlist ----------
  CollectionReference<Map<String, dynamic>> _wishlistCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('wishlist');

  Future<void> toggleWishlist(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _wishlistCol(user.uid).doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
        'productRef': _firestore.collection('products').doc(productId).path,
      });
    }
  }

  Stream<bool> isInWishlistStream(String productId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream<bool>.empty();
    return _wishlistCol(user.uid).doc(productId).snapshots().map((d) => d.exists);
  }

  Stream<List<Product>> getWishlistProducts() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _wishlistCol(user.uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) return <Product>[];
      final futures = snap.docs.map((d) async {
        final pid = d.id;
        final pDoc = await _firestore.collection('products').doc(pid).get();
        if (!pDoc.exists) return null;
        return Product.fromFirestore(pDoc);
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<Product>().toList();
    });
  }

  /// ---------- CRUD ----------
  Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toMap());
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  final List<Product> _cartItems = [];

  List<Product> get items => _cartItems;
  int get itemCount => _cartItems.length;
  double get totalAmount =>
      _cartItems.fold(0, (sum, item) => sum + (item.price ?? 0));

  void addItem(Product product) {
    _cartItems.add(product);
    notifyListeners();
  }

  void removeItem(Product product) {
    _cartItems.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}

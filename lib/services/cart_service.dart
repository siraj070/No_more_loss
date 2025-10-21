import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};
  
  List<CartItem> get itemsList => _items.values.toList();
  
  int get itemCount => _items.length;
  
  double get totalAmount => _items.values.fold(
    0.0, 
    (sum, item) => sum + item.totalPrice,
  );

  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;
    
    if (newQuantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId]!.quantity = newQuantity;
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }
}

import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.discountedPrice * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(
        map['productId'] ?? '',
        Map<String, dynamic>.from(map['product'] ?? {}),
      ),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'product': product.toMap(),
      'quantity': quantity,
    };
  }
}

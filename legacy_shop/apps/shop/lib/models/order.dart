import 'cart_item.dart';

class Order {
  Order(this.id, this.items, this.total);
  final String id;
  final List<CartItem> items;
  final double total;
}

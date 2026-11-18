import '../models/app_notification.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';

/// Talks to "the server". A singleton, like everything else here.
class ApiService {
  ApiService._();
  static final instance = ApiService._();

  final _orders = <Order>[];
  var _nextOrder = 1;

  Future<User> login(String email, String password) async {
    if (email != 'demo@shop.dev' || password != 'shop123') {
      throw Exception('Wrong email or password');
    }
    return User('u-1', 'Demo Shopper', email);
  }

  Future<List<Product>> products() async => [
    Product('p-1', 'Brass Desk Lamp', 49.0),
    Product('p-2', 'Stoneware Mug', 12.5),
  ];

  Future<List<Order>> orders(String userId) async => List.of(_orders);

  Future<Order> placeOrder(Order draft) async {
    final order = Order('o-${_nextOrder++}', draft.items, draft.total);
    _orders.add(order);
    return order;
  }

  Future<List<AppNotification>> notifications(String userId) async => [
    AppNotification('Welcome back', 'Good to see you again.'),
  ];

  void reset() {
    _orders.clear();
    _nextOrder = 1;
  }
}

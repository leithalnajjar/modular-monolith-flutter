import 'package:material_ui/material_ui.dart';
import 'package:notifications/notifications.dart';

import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/product.dart';
import 'models/user.dart';
import 'services/api_service.dart';
import 'widgets/price_label.dart';

/// Everything, in one place. Every screen reads it and changes it.
class AppState extends ChangeNotifier {
  User? currentUser;
  List<Product> products = [];
  List<CartItem> cart = [];
  List<Order> orders = [];
  String? error;

  /// The inbox now lives in the notifications module. AppState keeps a
  /// reference, and the old getters delegate to it, so screens that have
  /// not moved yet keep working.
  final inbox = Inbox();
  List<InboxMessage> get notifications => inbox.items;
  int get unreadCount => inbox.unreadCount;

  double get cartTotal =>
      cart.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  Future<void> login(String email, String password) async {
    try {
      currentUser = await ApiService.instance.login(email, password);
      products = await ApiService.instance.products();
      orders = await ApiService.instance.orders(currentUser!.id);
      // The API still speaks AppNotification; the inbox speaks
      // InboxMessage. The app translates at the edge.
      inbox.replaceAll([
        for (final n in await ApiService.instance.notifications(
          currentUser!.id,
        ))
          InboxMessage(n.title, n.body),
      ]);
      error = null;
    } on Exception catch (e) {
      error = '$e';
    }
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    cart = [];
    orders = [];
    inbox.clear();
    notifyListeners();
  }

  void addToCart(Product product) {
    for (final item in cart) {
      if (item.product.id == product.id) {
        item.quantity++;
        notifyListeners();
        return;
      }
    }
    cart.add(CartItem(product, 1));
    notifyListeners();
  }

  Future<void> placeOrder() async {
    final order = await ApiService.instance.placeOrder(
      Order('', List.of(cart), cartTotal),
    );
    orders.add(order);
    inbox.add(
      InboxMessage(
        'Order confirmed',
        '${order.items.length} items, ${formatPrice(order.total)}',
      ),
    );
    cart = [];
    notifyListeners();
  }

  void markNotificationsRead() {
    inbox.markAllRead();
    notifyListeners();
  }
}

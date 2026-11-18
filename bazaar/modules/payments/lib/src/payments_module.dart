import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:module_contract/module_contract.dart';
import 'package:payments_api/payments_api.dart';

import 'payment_gateway.dart';
import 'payment_service.dart';

/// Payments has no screens of its own: it is a service other modules use.
final class PaymentsModule extends FeatureModule {
  /// The app chooses the [gateway] adapter: a real provider in production,
  /// [FakePaymentGateway] for demos and tests.
  const PaymentsModule({required this.gateway});

  final PaymentGateway gateway;

  @override
  String get name => 'payments';

  @override
  void register(GetIt di) {
    di.registerLazySingleton<Payments>(
        () => PaymentService(gateway, di<EventBus>(), di<Clock>()));
  }
}

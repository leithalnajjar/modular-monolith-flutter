/// The payments module. Only the app imports this library: it picks the
/// gateway adapter and plugs the module in.
library;

export 'src/fake_payment_gateway.dart' show FakePaymentGateway;
export 'src/payment_gateway.dart'
    show Approved, Declined, GatewayOutcome, PaymentGateway, Unreachable;
export 'src/payments_module.dart' show PaymentsModule;

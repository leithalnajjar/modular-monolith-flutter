import 'package:material_ui/material_ui.dart';

String formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

class PriceLabel extends StatelessWidget {
  const PriceLabel(this.price, {super.key});
  final double price;

  @override
  Widget build(BuildContext context) => Text(formatPrice(price));
}

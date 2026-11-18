// apps/bazaar_app/lib/demo_data.dart
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

/// Sample products until the catalog talks to a server (Chapter 12).
const demoProducts = [
  Product(
    id: ProductId('p-1'),
    name: 'Brass Desk Lamp',
    price: Money(4900, 'USD'),
    inStock: true,
  ),
  Product(
    id: ProductId('p-2'),
    name: 'Stoneware Mug',
    price: Money(1250, 'USD'),
    inStock: false,
  ),
  Product(
    id: ProductId('p-3'),
    name: 'Linen Notebook',
    price: Money(1800, 'USD'),
    inStock: true,
  ),
];

/// Test support for modules that use the catalog: fakes of its contract,
/// and the checks that prove a [ProductCatalog] keeps its promises.
///
/// Import it from tests only. The app never imports this library, so none
/// of it is compiled into the release build.
library;

import 'catalog_api.dart';

export 'src/testing/fake_product_catalog.dart';
export 'src/testing/product_catalog_contract.dart';

import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Everything the product list screen can show.
sealed class ProductListState {
  const ProductListState();
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

final class ProductListLoaded extends ProductListState {
  const ProductListLoaded(this.products, {required this.hasMore});
  final List<Product> products;

  /// Whether another page may exist.
  final bool hasMore;
}

final class ProductListFailed extends ProductListState {
  const ProductListFailed(this.message);
  final String message;
}

/// The list screen's logic, kept out of the widget so it can be tested
/// without pumping any UI.
final class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit(this._catalog, {this.pageSize = 20})
      : super(const ProductListLoading());

  final ProductCatalog _catalog;
  final int pageSize;
  bool _loadingMore = false;

  /// Loads the first page (also used by the Retry button).
  Future<void> load() async {
    emit(const ProductListLoading());
    final result = await _catalog.search('', limit: pageSize);
    emit(switch (result) {
      Ok(:final value) =>
        ProductListLoaded(value, hasMore: value.length == pageSize),
      Err(:final failure) => ProductListFailed(failure.message),
    });
  }

  /// Appends the next page. Ignored while a page is already loading.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductListLoaded || !current.hasMore || _loadingMore) {
      return;
    }
    _loadingMore = true;
    final result = await _catalog.search('',
        limit: pageSize, offset: current.products.length);
    _loadingMore = false;
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(ProductListLoaded([...current.products, ...value],
            hasMore: value.length == pageSize));
      case Err():
        // Keep what we have; the user can try "Load more" again.
        emit(ProductListLoaded(current.products, hasMore: true));
    }
  }
}

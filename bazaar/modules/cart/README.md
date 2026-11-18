# cart

The shopping cart: lines, quantities, totals, and the cart badge.

- **Owners:** @your-org/checkout-experience (see `.github/CODEOWNERS`)
- **Contract:** `cart_api` - `CartReader` (look), `CartCommands` (change)
- **Uses:** `catalog_api` (`ProductCatalog` to price lines, `ProductActions`
  to add "Add to cart" to the product page)
- **Listens to:** `OrderPlaced` (checkout_api), `UserSignedOut` (identity_api)
  - the cart empties itself; see docs/adr/0002
- **Publishes:** nothing
- **Routes:** `/cart`; navigation entry "Cart" with a live badge
- **Storage:** scope `cart`, document `cart` (version 2); deleted when the
  cart is empty, so nothing is left after sign-out
- **Flags:** `cart.persist` (kill switch for storage; default on)

## Working on the cart

```bash
cd modules/cart
flutter test            # 22 tests, a few seconds
```

Tests use `FakeProductCatalog` from `package:catalog_api/testing.dart`,
never the real catalog.

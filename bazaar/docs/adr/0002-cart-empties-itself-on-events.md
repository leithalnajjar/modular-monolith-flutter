# 0002. The cart empties itself when it hears events

- Status: Accepted
- Date: 2026-11-19
- Deciders: checkout-experience, accounts

## Context

The cart must be emptied after an order is placed and when the user signs
out. Checkout and identity could call `cart.clear()`, but then both would
depend on the cart, and every new per-user module would need another call
in identity's sign-out code.

## Decision

Checkout publishes `OrderPlaced`, identity publishes `UserSignedOut`, and
the cart subscribes to both and empties itself. There is no public "clear
the cart" command.

## Consequences

- Checkout and identity do not depend on `cart_api` for this.
- Every module that keeps per-user data follows the same pattern, so
  sign-out needs no list of modules.
- The order of reactions is the subscription order; nothing may rely on
  the cart being empty before another subscriber runs.

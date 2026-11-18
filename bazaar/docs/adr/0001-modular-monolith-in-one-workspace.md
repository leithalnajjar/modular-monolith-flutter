# 0001. A modular monolith in one pub workspace

- Status: Accepted
- Date: 2026-11-19
- Deciders: architecture group

## Context

Bazaar is one Flutter app built by several teams. Separate apps or
separately versioned packages would add release coordination we do not
need; one `lib/` folder would let every feature depend on every other.

## Decision

Bazaar is one app made of modules. Each module is two packages in one pub
workspace: `<name>_api` (the contract) and `<name>` (the implementation).
Only the app depends on implementations. `tools/boundary_check` enforces the
rules on every pull request.

## Consequences

- One `pubspec.lock`, one analyzer run, one pull request for a change that
  spans modules.
- Contract changes are visible in review because they live in `_api`
  packages.
- Modules can be tested alone, in seconds.
- Rules that the compiler cannot see (layers, owners) need our own tool.

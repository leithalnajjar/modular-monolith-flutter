# 0003. Feature flag values are fixed for a run of the app

- Status: Accepted
- Date: 2026-11-19
- Deciders: architecture group

## Context

Flags can come from the build and, later, from a remote service. Values
that change while the app runs can change a screen while the user is using
it, and make modules disagree about a flag they read at different times.

## Decision

`FlagValues` is created once, at startup, and registered by the module
host. Values received later apply from the next launch.

## Consequences

- Every module sees the same values for the whole run; tests set them once.
- A remote kill switch takes effect on the next launch, not immediately.
  Emergencies that cannot wait are handled on the server.

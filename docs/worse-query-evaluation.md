# worse_query backend evaluation (feature branch only)

**Status: preflight only — not an exploit implementation or an Airlift replacement.**

This branch evaluates whether AirCard-iOS can *eventually* support a distinct
filesystem backend. It must not advertise `worse_query` file access unless the
actual backend has been implemented, licensed appropriately, reviewed and tested
on the intended iOS build. The existing `AirliftFFI` implementation is unchanged.

## Evidence and functional differences

- Upstream: <https://github.com/forcequitOS/worse_query> (GPL-3.0).
- Prior Airlift design: Rust `AirliftFFI`, paired-device loopback transport,
  AirTraffic file injection and a destructive file-export/readback operation.
- `worse_query` is a separate App Group-based sandbox-escape proof of concept,
  **not** an AirTraffic or AFC implementation and not compatible with the
  current `al_exploit_*` FFI calls as a drop-in library.
- Upstream does not claim access to every path AirCard currently writes,
  including its Wallet and SpringBoard targets; test target-by-target rather
  than infer access from its broad OS version claims.
- The public `worse_query` project and the Erosion integration are GPL-3.0.
  Review the resulting redistribution/license obligations before copying code
  into this currently MIT-licensed project.

## Safe preflight added here

`ios-app/WorseQueryPreflight.swift` inspects three prerequisites: iOS major
version 26 or 27, a configured App Group string, and availability of that
signed App Group container. This **does not** establish exploit availability,
provide access to other apps, or perform out-of-container file operations.
Its only input key is `WorseQueryAppGroupID` (optional, intentionally absent
from the shipped Info.plist). An App Group has to be provisioned using the
Apple Developer account and included in the final signed entitlements before
the check can pass; changing `Info.plist` alone is not sufficient.

`tests/WorseQueryPreflightTests.swift` covers unsupported OS, missing group,
malformed group, unavailable container and ready *prerequisites*; it always
asserts the exploit implementation is absent.

## Conditions to consider before a functional migration

1. Establish a legally compatible source/license and provenance strategy.
2. Verify every Wallet/Passcode/PosterBoard target and the readback/restore
   semantics without assuming broad sandbox escape equals safe write access.
3. Preserve exact-original-artwork backup and reversible rollback invariants;
   do not replace the prior destructive export with an untested read path.
4. Maintain an explicit unsupported-state and avoid silent fallback to another
   engine, especially on patched/unknown OS versions.
5. Validate on a test device with a known-restorable backup and signing profile.

The full iOS app cannot be built in a Linux-only environment: Xcode and the
repository's `xcodegen generate` step are required for the final compile and
unit test run.

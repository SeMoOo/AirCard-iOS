# worse_query migration assessment — AirCard-iOS

Status: **BLOCKED: not a drop-in replacement for Airlift**.

This assessment is intentionally non-executable. It records the filesystem and signing
requirements that must be verified before any implementation is attempted.
**No sandbox-escape code has been imported, no existing backend is replaced,
and no on-device testing has been performed.**

## Sources

- Upstream proof of concept: https://github.com/forcequitOS/worse_query (GPL-3.0)
- AirCard-iOS branch under review: `feature/worse-query-evaluation`
- Existing backend: `AirliftFFI.xcframework`, `rust-core/src/exploit.rs`
- UI entry points: `ios-app/WalletFlashIntegration.swift`, `ios-app/AppViewModel.swift`,
  `ios-app/TendiesEngine.swift`, `ios-app/WalletSafety.swift`

## Capability mismatch

The upstream README lists support for access within the following roots:

- `/var/containers/Data/System` (iOS 27)
- `/var/containers/Shared/SystemGroup/*` (iOS 27)
- `/var/mobile/Containers/Data/Application/*`
- `/var/mobile/Containers/Data/InternalDaemon/*`
- `/var/mobile/Containers/Data/PluginKitPlugin/*`
- `/var/mobile/Containers/Shared/AppGroup/*`
- `/var/mobile/Containers/Shared/AppGroup` (iOS 27)

The paths listed in the README are **not a blanket guarantee of read/write
semantics**, and paths outside them must be treated as unsupported until independently
demonstrated on an authorized test device.

| AirCard operation | Current target | In documented worse_query scope? | Action |
| --- | --- | --- | --- |
| Wallet card artwork | `/var/mobile/Library/Passes/Cards/<id>.pkpass` | **No** | Block migration for Wallet flash / exact restore |
| Wallet cache invalidation | `/var/mobile/Library/Passes/Cards/<id>.cache` or `.pkcache` | **No** | Block cache invalidation |
| Passcode themes | `/var/mobile/Library/Caches/TelephonyUI-*` | **No** | Block migration for passcode flash |
| PosterBoard app data | Resolved `/var/mobile/Containers/Data/Application/*` container | **Potentially** | Validate actual container and supported operations |
| PosterBoard user preferences | `/var/mobile/Library/Preferences` | **No** | Do not migrate preferences write |
| Device service operations | Pairing, tunnel, syslog, respring | **Not provided by the PoC API** | Requires separate design |

### API mismatch

Current app uses C exports such as `al_exploit_write_dir`,
`al_exploit_inject_folder`, `al_exploit_export_file`,
`al_find_app_container`, and device-service helpers.

The upstream `worse_query.h` exposes `worse_query(path, group, alt_flags, create_dir)`
and `worse_query_release(handle)`. It is **not** a compatible replacement for
these file-operation, backup, discovery, and service APIs. Do not map the old
functions to this PoC by name or assume its returned handle means an arbitrary
target has been safely written.

### Signing and licensing

- Upstream documentation requires an **App Group container**. This branch's
  `project.yml` has no `CODE_SIGN_ENTITLEMENTS` or App Group configuration,
  and its current source tree has no app entitlements file. An authorized,
  provisioned App Group must be configured before meaningful testing.
- `worse_query` is GPL-3.0. AirCard-iOS currently advertises MIT.
  Combining and distributing the code requires a license-compliance review.
- Verify the actual device's exact iOS build. The proof of concept claims
  iOS 26.0–26.7.2 / 27.2; this does not establish support for other releases
  or that every AirCard feature works on a listed release.

## Migration acceptance gates

1. Define a backend interface with explicit capability reporting rather than
   promising a blanket Airlift replacement.
2. Prove each required filesystem destination is reachable by documented,
   permitted APIs **before** enabling any write.
3. Preserve and validate originals before every Wallet-related write; abort if
   readback, backup, or rollback is unavailable.
4. No silent fallback, unverified write, or claim of success on an unsupported
   device or directory. Keep existing Airlift behavior unchanged until tests pass.
5. Validate on a separately backed-up, authorized test device and run the existing
   Wallet safety and UI test suites.
6. Resolve App Group provisioning and GPL-3.0 redistribution implications.

## Decision

**Do not remove Airlift or ship worse_query as a replacement at this stage.**
The PoC does not document access to two core AirCard destination roots.
An implementation that simply replaces the framework would regress Wallet
skin flashing and passcode theming, with potential original-artwork loss.

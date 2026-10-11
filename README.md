# GameShield v0.1

Native SwiftUI iPhone companion for game ad filtering. The app provides a safe on/off guide and DNS configuration instructions. **It cannot silently install a system-wide DNS profile.** No VPN extension or filtering entitlement is assumed.

## Build
GitHub Actions `ios-build.yml` builds an unsigned IPA using Xcode on macOS. Sign with your own certificate and provisioning profile. IPA installation does not itself enable DNS filtering.

## Filtering
The user can choose a trusted DNS provider, then manually configure encrypted DNS in iOS. DNS filtering is system-wide where supported and can affect apps other than games. Ads served from first-party domains may remain. No access to messages or calls is requested.

## Status
Source scaffold; not device-tested. Do not mistake the app's guide for active ad blocking.

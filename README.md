# GameShield v0.2 — DNS setup companion

Free, native SwiftUI guide to enabling public ad-filtering DNS for iOS games, including sideloaded games where their ad traffic uses blockable domains.

## What it does
- Opens the official AdGuard public DNS setup instructions.
- Guides the user through iOS approval, manual verification, and testing.
- Offers a clear recovery path if other apps are affected.
- Stores only in-memory manual checklist states. No analytics or message access.

## What it cannot do
- An ordinary sideloaded iOS app cannot silently change system DNS or verify the current DNS profile.
- The app itself **does not filter network traffic**. Filtering is performed by the independently installed DNS provider.
- DNS filters are system-wide, not per-game, and will not block all ads.
- Uninstalling GameShield will not remove a separately installed DNS profile.

## Build
The existing GitHub Actions workflow builds an unsigned IPA. Sign it with a valid iOS certificate and provisioning profile. The v0.2 build and on-device behavior must be verified independently.

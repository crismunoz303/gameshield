# CODM Rank Tracker v0.3.0 — Tactical UI edition

Native read-only COD Mobile iPhone rank companion. Built on branch \`codm-rank-tracker\` of crismunoz303/gameshield, with the GameShield main branch untouched.

## New in v0.3.0
- Military-inspired operations header, animated gold segmented rank progress, and layered tactical panels.
- Displays an authentic rank emblem **only when** the unofficial API supplies a codashop.com HTTPS image; fallback uses a custom shield.
- Expanded rank promotion route with checkpoints; redesigned color-coded XP performance dashboard.
- Preserves v0.2.0 UX: XP analytics, history, calculator, local cached changes and optional on-open refresh.
- Same bundle identifier and saved data keys so installs over v0.2.0 are intended to preserve locally stored progress.

## Limitations
- Rank/XP and returned icon are from a reverse-engineered, unofficial third-party service. Functionality and permission for ongoing access are not guaranteed.
- App has no accurate match-by-match kills, wins, losses, KD or exact XP per match, and does not claim it does.
- No password or game traffic modification; only the opted-in UID and the device IP are shared with the third-party provider for lookups. The rank icon is fetched from the provider's official-looking codashop.com CDN URL when provided.
- IPA built by GitHub Actions is unsigned and requires signing before installation. Compilation and IPA integrity do not prove installed-device behavior or service authorization.

## Building
GitHub Actions workflow CODM Rank Tracker - unsigned IPA runs Xcode on a macOS runner with \`CODE_SIGNING_ALLOWED=NO\`, assembles the IPA payload and validates ZIP integrity.

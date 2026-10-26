# CODM Rank Tracker v0.5.0 — Native iPhone ranked-match highlights

Native, read-only CODM iPhone companion built on the isolated `codm-rank-tracker` branch of `crismunoz303/gameshield`. GameShield main branch remains untouched.

## One app, four dashboards
1. **Command** — live profile, multiplayer rank/rating, animated progress, current division, the next rank, 6 XP snapshot cards, tier route, Legendary win-scenario calculator.
2. **Player** — nickname, player UID, player level, avatar art (trusted HTTPS CDN only), player level art, short ID, country name/code, country ID, internal MP rank class, rank emblem, current XP; last synced time and clearly labeled data source.
3. **Analytics** — time-filtered XP graph, user-entered Best Game So Far with optional rating, a match log, biggest observed between-lookup rating jump, and all-time rank change statistics.
4. **History** — locally stored changed readings, timestamps/ranks/XP deltas and sharing complete history as CSV *text*.

## Available API fields (verified in upstream source)
`success`, `nickname`, `pic`, `countryCode`, `countryId`, `shortId`, `level.current`, `level.image`, `rank.class`, `rank.multiplayerRank`, `rank.image`, `rank.rating`. The API also supplies a `dailyGift` URL, deliberately not called because claiming a gift changes state.

The API does **not** provide actual CODM match history, per-match XP, wins, losses, K/D, BR rank, weapon unlocks/inventory, or leaderboard placement. The app never fabricates these.

## Privacy, compatibility and limits
- Opt-in UID lookup to unofficial `callofdutymobile.vercel.app`; provider sees UID and IP address. No passwords or private account cookies.
- Activision terms restrict unauthorized data collection; the unofficial provider's uptime, accuracy and permission for automated access are unverified.
- No background polling or game modification. Lookup on app foreground/open or manual refresh; cached data remains usable if the service fails.
- Rank XP changes are *between saved readings* and may span multiple matches.
- Retains the existing bundle ID and `codm.player.<uid>` and `codm.history.<uid>` keys to preserve history from the installed native app. New `codm.matches.<uid>` storage is per UID, with optional rating gain. Updating in place requires the same signing identity.
- Local history capped at 1000 changed readings. CSV is shared as text, not a downloaded file.
- Only image URLs from a known codashop.com HTTPS CDN domain are remotely loaded.
- IPA artifacts are unsigned; use your usual iOS signing tool. CI verifies compile and ZIP structure but not iPhone installation.

## Build
GitHub Actions `CODM Rank Tracker - unsigned IPA` uses `macos-15`, `xcodegen`, `xcodebuild -sdk iphoneos CODE_SIGNING_ALLOWED=NO`, and ZIP integrity validation.

Source: `codm-rank-tracker/CODMRank.swift`. 

# Rank Command — shareable free CODM iPhone PWA

A standalone installable web companion for COD Mobile. No developer certificate, signing app, or native IPA is needed. Built as an independent PWA in `crismunoz303/gameshield`, branch `codm-rank-tracker`, folder `codm-pwa`.

## Hosting

Deploy this folder as the Vercel project root. Vercel's `api/player.js` provides the same-origin read-only proxy to the unofficial `callofdutymobile.vercel.app/user/:uid` service. Static web files serve the installable PWA. The app is for sharing via URL; users tap Safari Share → Add to Home Screen.

## Data

Live returned account fields: nickname, multiplayer rank, rank XP, player level, avatar URL, country code and ID, player short ID, level image URL, rank class and artwork URL. All available fields are in **Player**. Estimated rank milestones and wins-per-XP are in **Command**. Calculated XP deltas, daily/weekly changes, gains/losses and chart are in **Analytics**. The previous observations on the same phone are in **History**, with CSV export.

This provider does not offer genuine match history, K/D, kills, deaths, BR rank, loadouts or win rate. Never present these as retrieved. The proxy explicitly excludes the separate state-changing `dailyGift` endpoint.

## Privacy and caveats

- Each user enters their own UID and consents; the site ships without anyone's UID.
- Provider receives UID and IP, subject to its own handling. Site forwards only numeric UIDs and whitelists response fields. UID and readings persist only in browser localStorage. No central account database or analytics scripts. Local cache of upstream reads for 20 seconds may occur within a function instance.
- The source and unofficial API are not affiliated with Activision. Upstream reliability and authorization are not guaranteed. COD Mobile terms restrict unauthorized data collection.
- Update freshness is on open/return (no more than once per 60 seconds), manual refresh, or returning online. Offline shell remains available, while remote sync requires internet.
- XP changes represent intervals between readings, not verified individual matches. No credentials collected.
- App uses service worker for offline shell. HTTPS hosting required for Add to Home Screen experience.

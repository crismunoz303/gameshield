# Rank Command — authentic rank badges (Web v1.3.0)

A free installable iPhone web companion for Call of Duty Mobile Ranked. Native iPhone signing is not required.

**Art rule:** The hero displays only the original CODM rank image URL returned by the unofficial Codashop-based account lookup for each player's actual MP rank. Rank images are limited to their native pixel dimensions or smaller, with glow rendered separately outside the original PNG. The former custom vector badges and gallery have been removed from the live site.

The upstream PNGs are sometimes tiny. Keeping them at their native size avoids making them look worse, but does **not** make them HD. No verified complete set of original high-resolution CODM images for all divisions was located. Never describe the provider's thumbnail as HD, replace it with made-up insignias, or invent rank art for missing fields.

The site supports Rookie, Veteran, Elite, Pro, Master, Grand Master and Legendary implicitly through the per-user rank image URL returned by the lookup. Subdivisions are likewise determined by the service response, not guessed. A missing rank art link displays a text placeholder rather than fake artwork.

Data and privacy: The player enters their own UID; the website passes it to the unofficial provider. Stats are cached and XP-history stored locally per UID. No passwords, match automation or account changes. See `api/player.js`.

To host: Deploy `codm-pwa` as static+serverless on Vercel. Safari → Share → Add to Home Screen.

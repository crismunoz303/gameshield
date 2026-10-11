# GameShield v1.0 — DNS companion edition

A free, native iPhone app that guides users through enabling third-party DNS filtering for known game advertising domains. Supports the same DNS setup for App Store and sideloaded games.

## Features
- Official public DNS setup and Settings links
- DNS/ad-block test page (indicative, not a guarantee)
- Persisted manual checks for DNS activation, messaging, and game testing
- Troubleshooting and recovery links
- Resettable checklist and plain-language privacy disclosures
- Automated unsigned IPA build with archive integrity test and versioned artifact

## Important limitations
This app **does not itself block network traffic**. The user must independently install and approve a filtering DNS configuration profile in iOS. A standard sideloaded app cannot silently install or activate such a profile, verify its status, or filter only games. DNS filtering is system-wide and cannot block every ad, particularly first-party and rewarded-video ads. The third-party DNS provider handles DNS requests under its own policy. Removing GameShield does not remove a separately installed DNS profile.

## Build and validation
GitHub Actions builds `GameShield-v1.0-unsigned.ipa` using XcodeGen and Xcode. CI verifies that the app bundle exists and that the IPA ZIP archive passes `unzip -t`. The CI build is not equivalent to on-device signing, installation, DNS activation, or gameplay testing.

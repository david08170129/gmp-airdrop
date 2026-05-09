# GMP Airdrop iOS Companion App Plan

## Goal

Create a lightweight App Store companion app that improves iPhone UX for GMP Airdrop without changing the existing local transfer architecture.

## MVP Scope

- QR scanner screen for GMP Airdrop receiver URLs.
- Open existing wireless upload flow from a scanned QR code.
- Embedded upload page via WKWebView or Safari handoff.
- Share Sheet intake for photos, videos, PDFs, and general files.
- Local transfer history.
- Splash screen, GMP branding, and App Store-ready assets.
- Basic onboarding that explains local Wi-Fi transfer and no cloud/account behavior.

## Architecture

- Reuse current QR upload URLs produced by Windows and Android receivers.
- iPhone acts as a sender only in this first version.
- Use WKWebView when stable for uploads; keep Safari handoff as the fallback path.
- Stage shared files locally before passing them into the upload page.
- Store lightweight history on-device only.

## Explicit Non-Goals

- No iPhone local receive server.
- No peer discovery.
- No cloud relay.
- No account system.
- No advanced background transfer engine in the first release.

## Implementation Phases

1. Foundation
   - Add iOS-only Flutter companion shell.
   - Add onboarding, scanner, upload bridge, share intake, and history surfaces.
   - Add iOS permission strings and privacy metadata placeholders.

2. QR Scanner
   - Add camera QR scanner plugin.
   - Validate scanned URLs as local-network GMP Airdrop upload links.
   - Route valid URLs into upload view or Safari.

3. Upload View
   - Add WKWebView integration.
   - Support Safari handoff for maximum iOS file picker compatibility.
   - Preserve current browser-based upload protocol.

4. Share Sheet
   - Add iOS Share Extension target.
   - Stage shared files in an app group container.
   - Open the companion app with pending files ready to upload.

5. App Store Release Prep
   - Finalize screenshots, app privacy answers, support URL, marketing URL, and review notes.
   - Test iPhone Safari/WKWebView uploads against Windows and Android receivers on same Wi-Fi.

## Acceptance Criteria

- Existing Windows and Android flows remain unchanged.
- iOS app opens to a polished companion experience.
- QR scanner accepts GMP Airdrop local upload URLs only.
- Upload flow works through Safari or WKWebView.
- Shared files can be staged and sent to a scanned receiver.
- Transfer history records completed local upload sessions.

# GMP Airdrop v0.3.1-rc1

Release candidate checkpoint for local, offline GMP Airdrop transfers.

## Working Flows

- Android -> USB-C -> Windows
- iPhone/Android -> QR -> Windows
- iPhone -> QR -> Android

## Highlights

- QR wireless receive server for Windows and Android receivers.
- Mobile browser upload page for iPhone Safari and Android Chrome.
- Local Wi-Fi transfer only.
- Duplicate-safe filename handling.
- Chinese filename support.
- Photo/video/document categorization.
- Receiver free-space validation before upload.
- Progress and transfer history in the app.

## Known Limitations

- Android -> iPhone is QR download mode only/planned.
- Sender and receiver must be on the same Wi-Fi network.
- Large files need the sending phone screen awake until transfer completes.
- No peer discovery yet.
- No cloud relay, account, or AI features.

## Build Outputs

- Windows: `build/windows/x64/runner/Release/gmp_airdrop.exe`
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`

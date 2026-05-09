# GMP Airdrop v0.3.1-rc1 Test Checklist

## Android -> USB-C -> Windows

- [ ] On Android, select photos.
- [ ] On Android, select videos.
- [ ] On Android, select documents/files.
- [ ] Choose the USB-C drive root.
- [ ] Create or verify the `GMP_Airdrop` folder structure.
- [ ] Export selected files to USB-C.
- [ ] Move USB-C drive to Windows PC.
- [ ] Import from `GMP_Airdrop` into Windows folders.
- [ ] Confirm duplicate filenames are not overwritten.
- [ ] Confirm Chinese filenames are preserved.

## iPhone/Android -> QR -> Windows

- [ ] On Windows, open Wireless Receive.
- [ ] Start the local receive server.
- [ ] Confirm PC IP address, receive URL, QR code, and available space are shown.
- [ ] Scan QR from iPhone Safari.
- [ ] Scan QR from Android Chrome.
- [ ] Select photos, videos, and files in the mobile browser.
- [ ] Confirm total selected size is shown.
- [ ] Confirm receiver available space is shown.
- [ ] Confirm transfer is blocked if selected size exceeds available space.
- [ ] Upload files over same Wi-Fi.
- [ ] Confirm files save into the correct Windows folders.
- [ ] Confirm progress/history appears in the Windows app.

## iPhone -> QR -> Android

- [ ] On Android, open Wireless Receive.
- [ ] Start the local receive server.
- [ ] Confirm Android IP address, receive URL, QR code, and available space are shown.
- [ ] Scan QR from iPhone Safari.
- [ ] Select photos, videos, and files in Safari.
- [ ] Confirm total selected size is shown.
- [ ] Confirm Android available space is shown.
- [ ] Confirm transfer is blocked if selected size exceeds available space.
- [ ] Upload files over same Wi-Fi.
- [ ] Confirm files save into Android app-controlled `GMP_Airdrop/Wireless` storage.
- [ ] Confirm progress/history appears in the Android app.

## Known Limitations To Verify

- [ ] Android -> iPhone is QR download mode only/planned.
- [ ] Same Wi-Fi is required.
- [ ] Large files require the sending phone screen to stay awake.
- [ ] No cloud, account, AI, or peer discovery behavior is present.

## Release Build Checks

- [ ] `dart analyze`
- [ ] `flutter test`
- [ ] `flutter build windows`
- [ ] `flutter build apk`

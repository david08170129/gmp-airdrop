# GMP Airdrop

GMP Airdrop is a Flutter app for dropping photos, videos, and files between iPhone, Android phones, and Windows PCs.

This is not a website project. The target platforms are:

- iOS app
- Android app
- Windows desktop app

## v0.1 Scope

Mobile:

- Select photos
- Select videos
- Select files
- Export selected files to a USB-C drive
- Automatically create the `GMP_Airdrop` folder structure

Windows:

- Detect inserted USB drives
- Check whether a drive contains `GMP_Airdrop`
- Show file counts
- One-click import
- Import files to PC folders automatically
- Keep import history
- Manual search by filename, type, and date

## Folder Structure

```text
GMP_Airdrop/
  Photos/
  Videos/
  Documents/
    PDF/
    Word/
    Excel/
    PPT/
    Markdown/
    TXT/
    Others/
  Code/
    Python/
```

## Development

Install Flutter first, then run:

```powershell
flutter pub get
flutter run -d windows
```

For iOS and Android builds, use a machine with the required platform SDKs installed.

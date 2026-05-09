#define MyAppName "GMP Airdrop"
#define MyAppVersion "v0.3.1-rc1"
#define MyAppPublisher "Aunew"
#define MyAppDescription "Offline cross-platform transfer platform"
#define MyAppCopyright "Copyright © 2026 Aunew"
#define MyAppExeName "gmp_airdrop.exe"
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{9F6E8A31-38F7-4D70-88B0-9DF3E80F3B11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\GMP Airdrop
DefaultGroupName=GMP Airdrop
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=GMP_Airdrop_Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion=0.3.1.1
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppDescription}
VersionInfoCopyright={#MyAppCopyright}
VersionInfoTextVersion={#MyAppVersion}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion=0.3.1.1
VersionInfoOriginalFileName=GMP_Airdrop_Setup.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: checkedonce

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\GMP Airdrop"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall GMP Airdrop"; Filename: "{uninstallexe}"
Name: "{autodesktop}\GMP Airdrop"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch GMP Airdrop"; Flags: nowait postinstall skipifsilent

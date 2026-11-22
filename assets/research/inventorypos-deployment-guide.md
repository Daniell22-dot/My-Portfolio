# InventoryPOS — Deployment Guide

> Companion reference to
> [InventoryPOS-Project-Documentation.md](InventoryPOS-Project-Documentation.md)
> (Chapter 5). Covers build, publish, signing, configuration, database
> provisioning and packaging for every supported target.

## Supported targets

| Platform | TFM | Typical distribution |
|---|---|---|
| Windows desktop | `net8.0-windows10.0.19041.0` | MSIX (packaged) or unpackaged `.exe` |
| Android | `net8.0-android` | APK (sideload) or AAB (Play Store) |
| iOS | `net8.0-ios` | `.ipa` via App Store / TestFlight |
| Mac Catalyst | `net8.0-maccatalyst` | `.pkg` / Mac App Store |

iOS and Mac Catalyst builds require macOS with Xcode. Windows and Android can
be built on Windows.

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download) with the MAUI workload:

  ```powershell
  dotnet workload install maui
  ```

- **Android**: JDK 17 and the Android SDK (platform 34, build-tools 34.0.0).
- **Windows**: Windows 10 1809+ (10.0.17763.0) for the desktop target.
- **Docs export (optional)**: `pandoc` and `mmdc` on PATH plus Google Chrome.

### Environment variables (Windows)

Set once as user variables:

```powershell
setx JAVA_HOME "C:\Program Files\Java\jdk-17"
setx ANDROID_HOME "$env:LOCALAPPDATA\Android\Sdk"
setx ANDROID_SDK_ROOT "$env:LOCALAPPDATA\Android\Sdk"
```

> PowerShell 5.1 note: run `setx` from `cmd` semantics or restart the shell — the
> current session will not see the new values until restarted.

## Verify before packaging

Run the full test suite (must be green) and a debug build:

```powershell
dotnet test src\InventoryPOS.UnitTests\InventoryPOS.UnitTests.csproj
dotnet build src\InventoryPOS.Maui\InventoryPOS.Maui.csproj -f net8.0-windows10.0.19041.0
```

## Build & run

```powershell
# Windows desktop
dotnet build src\InventoryPOS.Maui\InventoryPOS.Maui.csproj -f net8.0-windows10.0.19041.0
dotnet run --project src\InventoryPOS.Maui -f net8.0-windows10.0.19041.0

# Android
dotnet build src\InventoryPOS.Maui\InventoryPOS.Maui.csproj -f net8.0-android
```

> The first Android build is slow (native tooling for all ABIs). Later builds
> reuse cached artifacts.

## Publish

### Windows desktop

Packaged MSIX (needs a signing certificate, see below):

```powershell
dotnet publish src\InventoryPOS.Maui\InventoryPOS.Maui.csproj `
  -f net8.0-windows10.0.19041.0 -c Release `
  -p:RuntimeIdentifierOverride=win10-x64 `
  -p:WindowsPackageType=MSIX
```

Unpackaged self-contained (simplest for internal distribution):

```powershell
dotnet publish src\InventoryPOS.Maui\InventoryPOS.Maui.csproj `
  -f net8.0-windows10.0.19041.0 -c Release `
  -p:WindowsPackageType=None `
  -p:RuntimeIdentifier=win10-x64 --self-contained true
```

### Android

```powershell
# Signed APK for sideloading
dotnet publish src\InventoryPOS.Maui\InventoryPOS.Maui.csproj `
  -f net8.0-android -c Release `
  -p:AndroidPackageFormat=apk `
  -p:AndroidKeyStore=true `
  -p:AndroidSigningKeyStore=inventorypos.keystore `
  -p:AndroidSigningKeyAlias=inventorypos `
  -p:AndroidSigningKeyPass=<password> `
  -p:AndroidSigningStorePass=<password>

# App Bundle for Google Play
dotnet publish src\InventoryPOS.Maui\InventoryPOS.Maui.csproj `
  -f net8.0-android -c Release -p:AndroidPackageFormat=aab
```

Create the keystore once (keep it and its passwords safe — losing them means you
cannot update the published app):

```powershell
keytool -genkeypair -v -keystore inventorypos.keystore `
  -alias inventorypos -keyalg RSA -keysize 2048 -validity 10000
```

### iOS / Mac Catalyst (on macOS)

```powershell
dotnet publish src\InventoryPOS.Maui\InventoryPOS.Maui.csproj -f net8.0-ios -c Release `
  -p:CodesignKey="Apple Distribution: Your Co (TEAMID)" `
  -p:CodesignProvision="InventoryPOS App Store"

dotnet publish src\InventoryPOS.Maui\InventoryPOS.Maui.csproj -f net8.0-maccatalyst -c Release
```

## App identity and versioning

Set in `src\InventoryPOS.Maui\InventoryPOS.Maui.csproj`:

| Property | Current value | Change for release |
|---|---|---|
| `ApplicationTitle` | `InventoryPOS` | Display name |
| `ApplicationId` | `com.companyname.inventorypos.maui` | Your reverse-DNS id |
| `ApplicationDisplayVersion` | `1.0` | Marketing version |
| `ApplicationVersion` | `1` | Increment every store upload |

## Runtime configuration

Integration features are **off by default** and are enabled per install/tenant.
Client-safe values may ship in the app; **secrets and webhook challenges must
only ever live on a trusted backend.**

### Preferences (non-secret)

| Key | Meaning | Default |
|---|---|---|
| `IntaSendPublishableKey` | IntaSend publishable key | empty |
| `IntaSendSandbox` | Use IntaSend sandbox | `true` |
| `EtimsBaseUrl` | KRA eTIMS base URL | sandbox URL |
| `EtimsTin` | KRA taxpayer PIN | empty |
| `EtimsBranchId` | KRA branch id | `00` |
| `EtimsDeviceSerial` | VSCU device serial | empty |
| `EtimsClientId` | eTIMS client id | empty |
| `Fiscal_{CC}_Endpoint` | Generic fiscal endpoint (CC = `TZ`/`UG`/…) | empty |
| `Fiscal_{CC}_Name` | Display name | `Fiscal (CC)` |
| `Fiscal_{CC}_ApiKey` | Bearer token | empty |
| `MoneyCurrencyCode` | ISO-4217 display currency | `KES` |
| `MoneyTaxMode` | `0` exclusive, `1` inclusive | exclusive |
| `MoneyCashRoundingStep` | Cash rounding step (minor units) | `0` |
| `SyncBaseUrl` / `SyncApiKey` | Offline-sync backend | empty |

Settings UI writes these via `MpesaOptionsProvider`, `EtimsOptionsProvider`,
`MoneyOptionsProvider` and `SyncOptionsProvider`. `MpesaOptionsProvider` also
exposes static defaults (`DefaultPublishableKey`, `DefaultSandbox`) that can be
baked into a build.

### Secure storage (secrets / keys)

| Key | Meaning |
|---|---|
| `DatabasePassphrase` | SQLCipher database passphrase |
| device master key | AES master key for field encryption (`CipherService`) |
| branch master key | Per-device key for branch signing (`SecureBranchKeyProvider`) |
| `UserId` / `BusinessId` / `IsLoggedIn` / `SessionTimestamp` | Session state (`AuthService`) |

## Database provisioning

- Local SQLite database at `FileSystem.AppDataDirectory/InventoryPOS.db`.
- EF Core migrations are applied automatically on first launch by
  `DataService.InitializeAsync`, including an upgrade path for databases created
  by earlier `EnsureCreated`-based builds.
- Migration history: see [Database_Schema.md](Database_Schema.md#migration-history).
- **Reset**: delete `InventoryPOS.db` in the app data folder and restart.
- **Rebuild DDL**: `dotnet ef dbcontext script -p src\InventoryPOS.Data\InventoryPOS.Data.csproj -s src\InventoryPOS.Data\InventoryPOS.Data.csproj -o database\Migrations\Schema.sql`

### Encryption at rest (SQLCipher)

Optional and **off by default**. Toggle in **Settings → Security**:

- Enabling generates a random 32-byte passphrase, migrates the existing database
  in place (`ATTACH … KEY` + `sqlcipher_export`), and stores the passphrase in
  `SecureStorage` under `DatabasePassphrase`.
- **A restart is required** so connections pick up the key.
- Disabling removes the passphrase (the file is re-created unencrypted on next
  plaintext open path). Keep backups before toggling.

## First-run / demo data

The seeder provisions demo tenants and accounts (all flagged
`RequiresPasswordChange`):

| Username | Password | Role |
|---|---|---|
| admin | Temp@Admin1 | Admin |
| manager | Temp@Manager1 | Manager |
| seller | Temp@Seller1 | Seller |

For a production tenant, use the in-app owner self sign-up (14-day free trial)
rather than the demo accounts.

## Documentation export

The Word build of the main design document:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\export-docs.ps1
```

This renders each ` ```mermaid ` block to `docs\diagrams\dNN.png` with
`mermaid-cli` then converts the Markdown to `.docx` with Pandoc. The script
accepts `-Source <path>` to export a different Markdown file.

`mmdc` needs `scripts\puppeteer-config.json` (Chrome path + `--no-sandbox`).

## Release checklist

1. `dotnet test` is green and all warnings reviewed.
2. Bump `ApplicationDisplayVersion` and `ApplicationVersion`.
3. Confirm `ApplicationId` matches the store listing.
4. Produce signed artifacts for each target store.
5. Verify a clean first run: migrations apply, demo/owner sign-up works, a sale
   completes offline.
6. Confirm integrations behave correctly when **unconfigured** (fiscal/sync must
   never block a sale).
7. If shipping DB encryption, validate the enable→restart→open flow on a copy.

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `error NETSDK1147: workload ... maui` | Run `dotnet workload install maui` |
| Android build fails on JDK | `JAVA_HOME` must point at JDK 17 and the shell restarted |
| Database locked / stale schema | Delete `InventoryPOS.db` and restart, or ensure only one app instance |
| SQLCipher-enabled DB won't open | Passphrase missing from `SecureStorage`; restore from backup or resume plaintext |
| Fiscal/sync features appear dead | They are opt-in — set the relevant preferences/SecureStorage values |
| `mmdc` fails during docs export | Set the Chrome path in `scripts\puppeteer-config.json` |
| `LF will be replaced by CRLF` warnings | Benign Git line-ending notice on Windows |

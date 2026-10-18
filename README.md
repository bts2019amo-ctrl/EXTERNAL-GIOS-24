# EXTERNAL GIOS 24

**OGIOS / ThreeOneOSFive / HyperRegedit** full source.

Public repo created for building unsigned IPA on GitHub macOS runners.

## Build (GitHub Actions)

Workflow: `.github/workflows/objective-c-xcode.yml`

- Runner: `macos-15`
- Produces **unsigned IPA**
- Trigger: `workflow_dispatch` (manual)
- Default scheme: `OGIOS`
- Default bundle id: `com.apple.mobile.MobileHouseArrest`

Go to **Actions** tab → **Build unsigned IPA** → **Run workflow**

## License key (local)

```
WINNER
```

Stored in Keychain. No network activation required.

## Structure

- `ThreeOneOSFive/` — app source (SwiftUI + ObjC + kexploit)
- `ThreeOneOSFive.xcodeproj/` — Xcode project
- `ThreeOneOSFive/Patches/` — embedded .3105 patch packages
- `ThreeOneOSFive/kexploit/` + `exploit/` — kernel exploit support
- `.github/workflows/` — macOS build pipeline

## Notes

Source extracted from `Full source 3105 OG.zip`.
Binary patch files (.3105) and AppIcon may need to be re-added if missing after first push (size limits).

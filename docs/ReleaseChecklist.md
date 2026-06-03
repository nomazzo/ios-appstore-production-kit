# Public Release Checklist

Use this checklist before pushing the repository to GitHub.

## Secrets And Identifiers

- No real AdMob app IDs or ad unit IDs
- No real StoreKit product IDs
- No bundle IDs, App IDs, team IDs, or provisioning references
- No commercial app names in package identifiers
- No private `Config.plist`

## Assets

- No commercial app icons
- No proprietary screenshots unless intentionally approved
- No paid or app-specific image/audio assets

## Code

- Source files compile as a Swift Package
- Tests demonstrate at least one purchase flow and one policy decision
- Examples use `com.example.*` identifiers
- Documentation explains what has been anonymized

## Suggested Scan

```sh
rg "ca-app-pub-|app id|bundle id|iap|product id|team id|Config.plist|883842|quantis"
```

Every match should either be a public test ID, a placeholder, or a checklist item.

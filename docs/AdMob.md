# AdMob Configuration Pattern

The public package does not depend directly on Google Mobile Ads. Instead, it includes
the configuration and policy pieces that are safe to publish:

- Ad unit type mapping
- Google test ad IDs
- Production placeholder fallback
- Non-personalized ad request extras
- Fullscreen ad cooldown logic

Real apps can add a thin adapter that converts these values into `GoogleMobileAds`
requests and banner/fullscreen ad objects.

## Example

```swift
let config = AdConfiguration(usesTestAds: true)
let adUnitID = config.adUnitID(for: .appOpen)

let policy = AdRequestPolicy(hasPersonalizedAdsConsent: false)
let extras = policy.extras // ["npa": "1"]
```

## Public Repo Notes

Do not publish real AdMob IDs. This repository uses official Google test IDs when
`usesTestAds` is true, and placeholder strings when production values are missing.

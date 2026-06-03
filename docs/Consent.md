# Consent Handling

Consent flows vary by SDK and target region, so the package exposes a small abstraction
instead of committing a vendor SDK directly:

```swift
public protocol ConsentClient {
    func requestConsentInfoUpdate() async throws -> ConsentState
    func presentConsentFormIfNeeded() async throws -> ConsentState
    func presentPrivacyOptions() async throws -> ConsentState
}
```

In a production app, a `ConsentClient` adapter can wrap Google UMP or another consent
provider. The package-level `ConsentCoordinator` keeps state and sequences the calls.

## Production Behaviors Shown

- Unknown, required, obtained, and not-required states
- Privacy options availability
- Personalized ad eligibility
- Async flow coordination

## Public Repo Notes

Do not commit test device identifiers, private debug configuration, or app-specific consent
screenshots.

# StoreKit 2 Purchase Flow

The StoreKit layer is built around a small protocol:

```swift
public protocol PurchaseClient {
    func products(for productIDs: [String]) async throws -> [PurchaseProductInfo]
    func purchase(productID: String) async throws -> PurchaseClientResult
    func currentEntitlementProductIDs() async -> Set<String>
    func sync() async throws
}
```

This keeps the app-facing purchase manager testable. Production builds use
`StoreKitPurchaseClient`; tests and demos can inject a mock client.

## Production Behaviors Shown

- Product loading from StoreKit 2
- Verified transaction handling
- Transaction finishing
- Current entitlement refresh
- Restore via `AppStore.sync()`
- Separate outcomes for purchased, cancelled, and pending states
- Entitlement persistence in `UserDefaults`

## Public Repo Notes

Use sample product IDs such as `com.example.demo.pro`. Do not commit real App Store
Connect product IDs.

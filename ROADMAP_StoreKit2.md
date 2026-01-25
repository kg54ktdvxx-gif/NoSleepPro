# AwakeApp - StoreKit 2 Monetization Roadmap

## Overview

This document outlines the implementation plan for StoreKit 2 in-app purchases, covering three monetization strategies that can be implemented individually or in combination.

---

## Monetization Options

| Strategy | Type | Price Range | Recurring | Complexity |
|----------|------|-------------|-----------|------------|
| **Tip Jar** | Consumable | $0.99 - $9.99 | Per purchase | Low |
| **Freemium** | Non-Consumable | $2.99 - $4.99 | One-time | Medium |
| **Subscription** | Auto-Renewable | $0.99 - $2.99/mo | Monthly/Yearly | High |

---

## Option 1: Tip Jar (Consumable IAPs)

### Concept
Users can "buy the developer a coffee" as a way to show appreciation. Tips can be purchased multiple times.

### Product IDs
```
com.yourcompany.awakeapp.tip.small      // $0.99 - "Small Coffee"
com.yourcompany.awakeapp.tip.medium     // $2.99 - "Large Coffee"
com.yourcompany.awakeapp.tip.large      // $4.99 - "Coffee & Pastry"
com.yourcompany.awakeapp.tip.generous   // $9.99 - "Coffee for the Team"
```

### UI Location
- Add "Support Development" or "Tip Jar" section in Settings → General tab
- Or dedicated "Support" tab in Settings

### Implementation

```swift
// TipJarManager.swift
import StoreKit

@MainActor
class TipJarManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchaseInProgress = false

    private let productIds = [
        "com.yourcompany.awakeapp.tip.small",
        "com.yourcompany.awakeapp.tip.medium",
        "com.yourcompany.awakeapp.tip.large",
        "com.yourcompany.awakeapp.tip.generous"
    ]

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Consumables: just finish the transaction
            await transaction.finish()
            // Show thank you message

        case .userCancelled:
            break

        case .pending:
            // Transaction pending (e.g., parental approval)
            break

        @unknown default:
            break
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let item):
            return item
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
```

### Tip Jar View

```swift
// TipJarView.swift
import SwiftUI
import StoreKit

struct TipJarView: View {
    @StateObject private var tipJar = TipJarManager()
    @State private var showThankYou = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.pink)

                Text("Support Development")
                    .font(.headline)

                Text("AwakeApp is made by an indie developer. Tips help keep the app updated and ad-free!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            // Tip options
            ForEach(tipJar.products, id: \.id) { product in
                TipButton(product: product) {
                    Task {
                        try? await tipJar.purchase(product)
                        showThankYou = true
                    }
                }
            }

            Spacer()
        }
        .padding()
        .task {
            await tipJar.loadProducts()
        }
        .alert("Thank You!", isPresented: $showThankYou) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your support means the world! Enjoy your coffee ☕️")
        }
    }
}

struct TipButton: View {
    let product: Product
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink)
                    .cornerRadius(20)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
```

---

## Option 2: Freemium Model (Non-Consumable IAP)

### Concept
App is free with basic features. Premium features unlocked with one-time purchase.

### Feature Split

| Free Features | Premium Features ($2.99) |
|--------------|-------------------------|
| Timer presets (all 6) | App Triggers |
| Manual toggle | Schedules |
| Menu bar countdown | Battery Protection |
| Basic UI | Keyboard Shortcut (⌘⇧A) |
| | Allow Display Sleep |
| | Priority Support |

### Product ID
```
com.yourcompany.awakeapp.premium    // $2.99 - "AwakeApp Premium"
```

### Implementation

```swift
// PremiumManager.swift
import StoreKit

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium = false
    @Published var product: Product?

    private let productId = "com.yourcompany.awakeapp.premium"

    private init() {
        // Check existing purchases on launch
        Task {
            await updatePurchasedProducts()
            await loadProduct()
        }

        // Listen for transaction updates
        listenForTransactions()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productId])
            product = products.first
        } catch {
            print("Failed to load product: \(error)")
        }
    }

    func purchase() async throws {
        guard let product = product else { return }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPremium = true

        case .userCancelled, .pending:
            break

        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        // Sync with App Store
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productId {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = false
    }

    private func listenForTransactions() {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let item):
            return item
        }
    }
}
```

### Paywall View

```swift
// PaywallView.swift
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var premium: PremiumManager
    @Environment(\.dismiss) var dismiss
    @State private var isPurchasing = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)

                Text("Unlock Premium")
                    .font(.title.bold())

                Text("One-time purchase. No subscription.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Features
            VStack(alignment: .leading, spacing: 16) {
                PremiumFeatureRow(icon: "app.badge", title: "App Triggers", description: "Auto-activate for Zoom, Teams, etc.")
                PremiumFeatureRow(icon: "calendar", title: "Schedules", description: "Stay awake during work hours")
                PremiumFeatureRow(icon: "battery.50", title: "Battery Protection", description: "Auto-stop when battery is low")
                PremiumFeatureRow(icon: "keyboard", title: "Keyboard Shortcut", description: "Toggle with ⌘⇧A anywhere")
                PremiumFeatureRow(icon: "display", title: "Display Sleep", description: "Keep system awake, display can sleep")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)

            Spacer()

            // Purchase button
            if let product = premium.product {
                Button(action: {
                    Task {
                        isPurchasing = true
                        try? await premium.purchase()
                        isPurchasing = false
                        if premium.isPremium { dismiss() }
                    }
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Unlock for \(product.displayPrice)")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isPurchasing)
            }

            // Restore
            Button("Restore Purchase") {
                Task { await premium.restorePurchases() }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 550)
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### Gating Premium Features

```swift
// In MenuBarView or anywhere features are accessed
struct SomeFeatureView: View {
    @EnvironmentObject var premium: PremiumManager
    @State private var showPaywall = false

    var body: some View {
        Button("Use Premium Feature") {
            if premium.isPremium {
                // Use feature
            } else {
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(premium)
        }
    }
}
```

---

## Option 3: Subscription Model (Auto-Renewable)

### Concept
Monthly or yearly subscription for premium features. Best for ongoing revenue.

### Product IDs
```
com.yourcompany.awakeapp.subscription.monthly   // $0.99/month
com.yourcompany.awakeapp.subscription.yearly    // $6.99/year (42% savings)
```

### Subscription Group
```
Group Name: "AwakeApp Premium"
Group ID: 21000000 (assigned by App Store Connect)
```

### Implementation

```swift
// SubscriptionManager.swift
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var currentSubscription: Product.SubscriptionInfo?
    @Published var renewalDate: Date?

    private let productIds = [
        "com.yourcompany.awakeapp.subscription.monthly",
        "com.yourcompany.awakeapp.subscription.yearly"
    ]

    private init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
        listenForTransactions()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()

        case .userCancelled, .pending:
            break

        @unknown default:
            break
        }
    }

    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIds.contains(transaction.productID) {
                    isSubscribed = true
                    renewalDate = transaction.expirationDate
                    return
                }
            }
        }
        isSubscribed = false
        renewalDate = nil
    }

    func manageSubscription() async {
        if let windowScene = NSApp.keyWindow?.windowScene {
            try? await AppStore.showManageSubscriptions(in: windowScene)
        }
    }

    private func listenForTransactions() {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let item):
            return item
        }
    }
}
```

### Subscription Paywall View

```swift
// SubscriptionPaywallView.swift
import SwiftUI

struct SubscriptionPaywallView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)

                Text("AwakeApp Premium")
                    .font(.title.bold())

                Text("Unlock all features")
                    .foregroundColor(.secondary)
            }

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                SubscriptionFeature(text: "App Triggers & Schedules")
                SubscriptionFeature(text: "Battery Protection")
                SubscriptionFeature(text: "Keyboard Shortcuts")
                SubscriptionFeature(text: "Priority Support")
                SubscriptionFeature(text: "Future Premium Features")
            }
            .padding()

            // Subscription options
            ForEach(subscription.products, id: \.id) { product in
                SubscriptionOptionCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onSelect: { selectedProduct = product }
                )
            }

            Spacer()

            // Subscribe button
            Button(action: {
                guard let product = selectedProduct else { return }
                Task {
                    isPurchasing = true
                    try? await subscription.purchase(product)
                    isPurchasing = false
                    if subscription.isSubscribed { dismiss() }
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Subscribe")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedProduct != nil ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(selectedProduct == nil || isPurchasing)

            // Legal text
            Text("Cancel anytime. Subscription auto-renews until cancelled.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Restore
            Button("Restore Purchase") {
                Task { await subscription.updateSubscriptionStatus() }
            }
            .font(.caption)
        }
        .padding()
        .frame(width: 400, height: 600)
        .onAppear {
            selectedProduct = subscription.products.last // Default to yearly
        }
    }
}

struct SubscriptionFeature: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var isYearly: Bool {
        product.id.contains("yearly")
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.headline)

                        if isYearly {
                            Text("SAVE 42%")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    Text(isYearly ? "Best value" : "Flexible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.headline)
                    Text(isYearly ? "/year" : "/month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
```

---

## App Store Connect Setup

### 1. Create In-App Purchases

1. Go to App Store Connect → Your App → In-App Purchases
2. Click "+" to create new IAP

**For Consumables (Tip Jar):**
- Type: Consumable
- Reference Name: "Small Tip"
- Product ID: `com.yourcompany.awakeapp.tip.small`
- Price: $0.99
- Localization: Add display name, description

**For Non-Consumable (Premium):**
- Type: Non-Consumable
- Reference Name: "AwakeApp Premium"
- Product ID: `com.yourcompany.awakeapp.premium`
- Price: $2.99
- Localization: Add display name, description

**For Subscriptions:**
- Go to Subscriptions → Create Subscription Group
- Group name: "AwakeApp Premium"
- Add products: Monthly ($0.99), Yearly ($6.99)

### 2. StoreKit Configuration File (Testing)

Create `StoreKitConfig.storekit` for local testing:

```json
{
  "products": [
    {
      "id": "com.yourcompany.awakeapp.tip.small",
      "type": "Consumable",
      "displayPrice": "0.99",
      "displayName": "Small Coffee",
      "description": "Buy the developer a small coffee"
    },
    {
      "id": "com.yourcompany.awakeapp.premium",
      "type": "NonConsumable",
      "displayPrice": "2.99",
      "displayName": "AwakeApp Premium",
      "description": "Unlock all premium features"
    }
  ]
}
```

### 3. Entitlements Update

Add to `AwakeApp.entitlements`:
```xml
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.yourcompany.awakeapp</string>
</array>
```

---

## Recommended Strategy

### Phase 1: Launch (Current)
- **Price: $2.99** one-time purchase
- No IAPs initially
- Build user base and reviews

### Phase 2: Add Tip Jar (Month 2)
- Keep base price at $2.99
- Add tip jar for supporters
- Low effort, additional revenue

### Phase 3: Evaluate (Month 6)
Based on metrics, choose:

| Metric | Action |
|--------|--------|
| High downloads, low conversion | Go Freemium |
| Steady sales, loyal users | Keep paid + tips |
| Feature requests for updates | Consider subscription |

### Phase 4: Freemium or Subscription (Month 6+)
If going freemium:
- Make app free
- Gate premium features behind $2.99 IAP
- Keep tip jar

If going subscription:
- Offer both one-time and subscription
- One-time: $4.99 (premium forever)
- Subscription: $0.99/mo or $6.99/year

---

## Testing Checklist

- [ ] Create StoreKit configuration file
- [ ] Test in sandbox environment
- [ ] Verify purchase flow for each IAP type
- [ ] Test restore purchases
- [ ] Test subscription renewal/expiration
- [ ] Test interrupted purchases
- [ ] Test parental controls (Ask to Buy)
- [ ] Verify receipt validation
- [ ] Test on real device with sandbox account

---

## Files to Create

```
AwakeApp/
├── Store/
│   ├── StoreManager.swift        # Unified store manager
│   ├── TipJarManager.swift       # Consumable tips
│   ├── PremiumManager.swift      # Non-consumable unlock
│   ├── SubscriptionManager.swift # Auto-renewable subs
│   └── StoreError.swift          # Error types
├── Views/
│   ├── TipJarView.swift
│   ├── PaywallView.swift
│   └── SubscriptionPaywallView.swift
└── StoreKitConfig.storekit       # Testing configuration
```

---

## Revenue Projections

Assuming 1,000 monthly downloads:

| Model | Conversion | Revenue/Month |
|-------|------------|---------------|
| Paid ($2.99) | 100% | $2,990 |
| Freemium (10% convert) | 10% | $299 |
| Freemium + Tips | 10% + 2% | $359 |
| Subscription (5% @ $0.99) | 5% | $50 + recurring |

**Recommendation:** Start paid at $2.99, add tip jar later.

---

## Next Steps

1. Decide on initial monetization strategy
2. Set up App Store Connect IAPs
3. Create StoreKit configuration for testing
4. Implement chosen IAP managers
5. Add IAP UI to Settings
6. Test thoroughly in sandbox
7. Submit for review with IAPs

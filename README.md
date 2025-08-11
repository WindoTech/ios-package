
# BeaconBar iOS Package

A Swift package providing the **BeaconBar** SDK for iOS apps.

---

## Installation

### Option 1 — Add via Xcode

1. Open your iOS project in **Xcode**.

2. Go to **File → Add Packages…**.

3. Enter the repository URL:

   ```
   https://github.com/WindoTech/ios-package.git
   ```

4. Select a branch, tag, or commit (recommended: latest tagged release).

5. Add the package to your app target.

---

### Option 2 — Add via `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/WindoTech/ios-package.git", branch: "main")
]
```

Then link the product:

```swift
.target(
    name: "YourAppTarget",
    dependencies: [
        .product(name: "BeaconBar", package: "ios-package")
    ]
)
```

---

## Usage Example — SwiftUI Integration

```swift
import SwiftUI
import BeaconBar

struct ContentView: View {
    @State private var isBeaconBarPresented = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text("BeaconBar iOS Integration")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button("Launch BeaconBar") {
                launchBeaconBar()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Launch BeaconBar (Custom Config)") {
                launchBeaconBarCustom()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
    
    // Basic launch
    private func launchBeaconBar() {
        Task { @MainActor in
            let config = BeaconConfig(
                isDebug: true,
                orgId: "XXXXX",
                userIdentifier: "user-123"
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                BeaconBar.launch(from: rootViewController, config: config)
            }
        }
    }
    
    // Custom UI launch
    private func launchBeaconBarCustom() {
        Task { @MainActor in
            let uiConfig = BeaconUiConfig(
                width: UIScreen.main.bounds.width * 0.9,
                height: UIScreen.main.bounds.height * 0.8,
                marginLeading: 20,
                marginTop: 50,
                marginTrailing: 20,
                marginBottom: 50,
                padding: 10,
                alignment: .center
            )
            let config = BeaconConfig(
                isDebug: true,
                orgId: "XXXXX",
                userIdentifier: "user-123",
                userMetadata: [
                    "name": "Test User",
                    "email": "test@example.com",
                    "plan": "premium"
                ],
                uiConfig: uiConfig
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                BeaconBar.launch(from: rootViewController, config: config)
            }
        }
    }
}
```

---

## Alternative Integrations

### Reusable Button Component

```swift
struct BeaconBarButton: View {
    let title: String
    let config: BeaconConfig
    
    var body: some View {
        Button(title) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                BeaconBar.launch(from: rootViewController, config: config)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}
```

### Present as Sheet

```swift
.sheet(isPresented: $isBeaconBarPresented) {
    BeaconBarViewControllerRepresentable(
        config: BeaconConfig(
            isDebug: true,
            orgId: "XXXXX",
            userIdentifier: "user-123"
        ),
        isPresented: $isBeaconBarPresented
    )
}
```

---

## iOS Privacy Keys

Add these privacy descriptions to your app's **Info.plist**:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone for voice features.</string>
<key>NSCameraUsageDescription</key>
<string>This app uses the camera for photo and video features.</string>
```

---

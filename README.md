# iOSChatBot

<img width="193" height="552" alt="New SARA 2 0" src="https://github.com/user-attachments/assets/67844d5e-38d2-48d1-928f-c1caa2cf9ca6" />

<img width="193" height="552" alt="New SARA 5 0" src="https://github.com/user-attachments/assets/5d4ef138-5561-49cb-bba8-02e2eb8c6d91" />

<img width="193" height="552" alt="New SARA 6 0" src="https://github.com/user-attachments/assets/0eeeaa67-449b-41a2-970f-ce13b506710b" />

This document describes the Chatbot feature implemented inside the iOS app. It is intended for maintainers, mobile engineers, and reviewers who want a quick but thorough understanding of how the chatbot is structured, how to run it locally, and how to extend or debug it.

Goals

- Provide a conversational shopping assistant that can:
  - Exchange text messages with a backend (ADK/chat API)
  - Offer quick-reply chips (buttons)
  - Surface product/deal cards and deep-link into product detail screens
  - Support speech-to-text (microphone + speech recognition)
  - Render GIFs and rich route bubbles where applicable

Architecture overview

- UI (SwiftUI)
  - `ChatBotView.swift` — main chat screen built with SwiftUI, contains message rendering, input bar, quick replies, and navigation to `ProductDetailView`.
  - Subviews: `Chatbubble`, `DealCard`, `QuickReplyButton`, `TypingIndicator`, `GIFView`, `ChatInputView` and utility `FlowLayout`.

- ViewModels & Clients
  - `ChatViewModel` — holds session state (sessionId, userId, cookie) and coordinates initial setup.
  - `ChatApiClient` — network client that sends user messages to the chatbot backend and receives structured responses (text, cards, GIFs, product lists).
  - `CSApiViewModel` — app-specific API view model used to refresh the cart and fetch product metadata when a deal card is tapped.
  - `SpeechRecognizer` (or similar) — handles microphone permission and speech-to-text streaming.

- Data
  - Messages are currently stored as an array of tuples in the view state (Bool for user, MessageType enum, and Date). Recommended refactor: replace tuple with a typed `ChatMessage` model for clarity and testability.
  - Product metadata is resolved via a `CoreDataManager` or `CSApiViewModel` calls (look for `getProductDetailsByName` usages).

Key files (paths relative to project root `iosApp/iosApp`)

- View
  - `View/ChatBotView/ChatBotView.swift` — main chat screen + local README
  - `View/ChatBotView/README.md` — component-focused documentation (already present)

- Models & ViewModels
  - `ViewModel/ChatViewModel.swift` — session state & helpers
  - `ViewModel/ChatApiClient.swift` — network client (or wherever `ChatApiClient` is defined)
  - `ViewModel/CSApiViewModel.swift` — cart/product API interactions

- Supporting resources
  - Assets: avatar/send icons `CS - Sara`, `CS - Send` (verify `Assets.xcassets`)
  - Local data: product images / sample GIFs (if bundled)

Dependencies

- CocoaPods-managed libraries (Pods/ directory present): network clients, any JSON/ADK helpers, and (optionally) GIF helpers.
- Apple frameworks: SwiftUI, AVFoundation (if using audio recording), Speech (if using Speech framework for transcription), Foundation, UIKit (for GIF rendering helpers), CoreData (if product metadata is stored locally).

Permissions

Add the following keys to `Info.plist` with user-facing messages if you use the corresponding features:

- `NSMicrophoneUsageDescription` — required for microphone input
- `NSSpeechRecognitionUsageDescription` — required for Speech framework transcription
- `NSCameraUsageDescription` — not required by chat itself but may be needed if chat links to product scanning features

Local setup and build

1. Ensure system prerequisites are installed (Xcode + CocoaPods):

```bash
# Install CocoaPods if needed
sudo gem install cocoapods

# Ensure Xcode command line tools present
xcode-select --install
```

2. From the `iosApp` folder, install pods (if you need to refresh or reproduce environment):

```bash
cd "/Users/srushtichoudhari/Desktop/Retail X/CornerShopAppMobileAndroid/iosApp/"
pod install --repo-update
```

3. Open the workspace (always open the `.xcworkspace` when CocoaPods are used):

```bash
open iosApp.xcworkspace
```

4. Build and run on a simulator or device. For speech features test on a physical device.

How it works (high-level flow)

1. User types text or taps a quick-reply chip (or uses the mic to speak).
2. `ChatBotView` appends the user's message to the local messages array and calls `ChatApiClient.sendMessage(...)`.
3. `ChatApiClient` calls the backend and returns a structured response containing one or more elements (text, quick replies, deal cards, gif urls, routing instructions).
4. `ChatBotView` converts backend response elements into `MessageType` values and appends them to the messages array. The view updates automatically.
5. If a `DealCard` is tapped, `CSApiViewModel` or `CoreDataManager` is used to load product details and navigate to `ProductDetailView`.

Testing

- Unit tests
  - Add tests for `ChatViewModel` and `ChatApiClient` parsing logic. Validate mapping from backend payloads to `MessageType`.
  - Add tests for utility components such as `FlowLayout` and any timestamp formatting helpers.

- Manual / UI testing
  - Validate quick replies, card navigation, and GIF rendering. Test the mic flow on a device.

- Suggested smoke test commands (from project root):

```bash
# Run unit tests via xcodebuild (example, adjust scheme/name as needed)
xcodebuild test -workspace iosApp.xcworkspace -scheme iosApp -destination "platform=iOS Simulator,name=iPhone 14"
```

Troubleshooting

- No microphone permission prompt or mic not working
  - Confirm `NSMicrophoneUsageDescription` exists in `Info.plist`, then uninstall and re-install the app to re-trigger the permissions prompt.

- Chat API responses are empty or parsing fails
  - Log the raw backend response in `ChatApiClient` and add defensive parsing. Add unit tests with sample payloads.

- Missing images or assets
  - Check `Assets.xcassets` contains required named assets and that they are included in the correct app target.

- GIFs don't animate
  - GIFs are rendered via UIKit helpers. Ensure the GIF data is valid. For remote GIFs, verify the URL and network connectivity.

Recommended refactors and enhancements

- Replace the messages tuple array with a typed `ChatMessage` struct:

```swift
struct ChatMessage: Identifiable, Equatable {
  let id: UUID
  let isUser: Bool
  let type: MessageType
  let timestamp: Date
}
```

- Move backend response -> MessageType parsing into `ChatApiClient` or `ChatViewModel` so the view receives a stream of typed messages (single responsibility).
- Introduce an interface/adapter for `ChatApiClient` so you can easily swap between a mocked local implementation and the real backend for integration tests.
- Add accessibility labels for interactive elements and VoiceOver support for messages.

Extending the chatbot

- Add support for rich cards with action buttons (e.g., add-to-cart directly from chat).
- Add offline/local mode where canned responses and local product catalog are used for demos.
- Add analytics hooks for message sends, quick reply taps, and card clicks to track usage.

Contributor guidance

- Always open the `.xcworkspace` after updating pods.
- Keep UI and parsing/logic separate. View files should be presentation only.
- Add unit tests for any parsing or state transitions you introduce.
- Update `View/ChatBotView/README.md` for component-level changes and keep this project README for cross-cutting concerns.

Contact / Next work items

If you want, I can:
- Extract the message parsing logic into `ChatApiClient` and add unit tests for the parsing layer.
- Replace tuple-based message storage with `ChatMessage` model and update views.
- Provide a minimal mock server or a set of JSON fixtures with sample backend responses for offline testing.

License

Follow the repository license (add a LICENSE file at repo root if one is not present).

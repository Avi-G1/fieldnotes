# SDK version and local compatibility patch

Fieldnotes uses RunAnywhere Swift SDK 0.20.24 from the official Swift distribution repository: `https://github.com/RunanywhereAI/runanywhere-swift.git`. The vendored source is based on tag `0.20.24`, commit `f269ccd53f04b2fa2a4767f7264a40363b7ec74a`. The upstream license is at `Vendor/runanywhere-swift/LICENSE`; Git metadata is excluded.

The initial build and telemetry fixes are:

1. In `Sources/RunAnywhere/Features/TTS/Services/AudioPlaybackManager.swift`, the `AVAudioPlayerDelegate` conformance moves to a separate `@preconcurrency` extension. Without this change, Swift 6.4 infers main-actor isolation from the Objective-C delegate conformance, even though the manager already uses lock-protected state and declares `@unchecked Sendable`. Keeping the conformance separate preserves its cross-task use without spreading actor isolation through the audio pipeline.
2. `Sources/RunAnywhere/Features/Downloads/DownloadNotifier.swift` skips optional local notifications when `Bundle.main.bundleIdentifier` is absent. This lets command-line and SwiftPM smoke hosts download models without an app bundle or notification center.
3. `Sources/RunAnywhere/Foundation/Bridge/CppBridge.swift` checks for `RUNANYWHERE_SWIFT_LOCAL_ONLY=1` before registering the telemetry manager, telemetry sink, and device-registration callbacks. Fieldnotes sets the switch before calling `RunAnywhere.initialize`. The SDK's local-only initialization also skips Phase 2. Auth, device registration, and telemetry stay off, but model downloads still make an outbound request to Hugging Face. EventBus continues to report local model lifecycle events.

The patch disables telemetry when the app selects local-only mode. SDK inference and generation code are unchanged.

Both the Swift package manifest and Xcode project point to the local vendor directory. To refresh it, fetch the official tag, reapply and review the actor, notification, telemetry, and model-only transport changes, run the policy tests and offline inference check, then update the upstream commit and these patch notes. This compatibility patch is maintained here; it is not an upstream RunAnywhere change.

## Model-only transport

The shared HTTP adapter remains registered because model planning uses it. In local-only mode, its RequestSnapshot permits only body-free GET/HEAD requests to the pinned Qwen artifact URL. Redirects must start from that approved request and use HTTPS Hugging Face/Xet storage hosts. `Tests/NetworkPolicyTests.swift` tests the policy against the source file. Local-only mode also disables optional download notifications.

## Native entry points

The app linker retains and exports the 133 native entry points in `NATIVE-SYMBOLS.txt` for the SDK's dynamic lookup. `-all_load` also pulled in unsupported optional backend registration objects, so the project uses explicit retention flags in both `Package.swift` and the Xcode target.

In local-only mode, `Device.persistentId` returns an ephemeral UUID cached for the process instead of querying Keychain. This applies to both SDK initialization entry points. A live Mac stack sample showed `SecItemCopyMatching` blocking startup after the app was rebuilt. Outside local-only mode, the SDK still uses its persistent ID behavior. Keychain settings and access controls are unchanged.


On macOS, local-only mode stores models under `~/Library/Application Support/Fieldnotes` instead of Documents. Repeated live stack samples showed `try_restore_model_manifest_by_id` waiting while opening a file under Documents. After the existing model was copied to the Application Support cache, initialization and two consecutive inference runs completed. iOS storage is unchanged, and files in Documents were kept. Other Mac installs using the old path must copy their model directory or download the model once into the new cache.

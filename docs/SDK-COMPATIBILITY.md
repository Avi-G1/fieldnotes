# SDK version and local compatibility patch

Fieldnotes uses RunAnywhere Swift SDK 0.20.24, sourced from the official Swift distribution repository at `https://github.com/RunanywhereAI/runanywhere-swift.git`. The vendored source is the exact `0.20.24` tag at commit `f269ccd53f04b2fa2a4767f7264a40363b7ec74a`. Its upstream `LICENSE` is retained in `Vendor/runanywhere-swift/LICENSE`; `.git` metadata is excluded.

Three local compatibility fixes are applied to the vendored package:

1. `Sources/RunAnywhere/Features/TTS/Services/AudioPlaybackManager.swift` moves the `AVAudioPlayerDelegate` conformance to a separate extension and marks it `@preconcurrency`. Swift 6.4 otherwise infers main-actor isolation from the Objective-C delegate conformance, despite the manager's existing lock-protected state and `@unchecked Sendable` declaration. Scoping the conformance keeps its intended cross-task use without spreading actor isolation into the audio pipeline.
2. `Sources/RunAnywhere/Features/Downloads/DownloadNotifier.swift` skips optional local notifications when `Bundle.main.bundleIdentifier` is absent. Downloading through the SDK must also work from command-line and SwiftPM smoke hosts that have no app bundle or notification center.
3. `Sources/RunAnywhere/Foundation/Bridge/CppBridge.swift` checks the SDK's existing `RUNANYWHERE_SWIFT_LOCAL_ONLY=1` mode before registering the telemetry manager/sink and device-registration callbacks. Fieldnotes sets this switch before `RunAnywhere.initialize`. The SDK's existing local-only initialization path also skips Phase 2. This keeps auth, device registration, and telemetry off; downloading the model still requires an outbound request to Hugging Face. EventBus remains active for local model lifecycle events.

No inference or generation code in the SDK was changed. The opt-out is explicit and scoped to local-only mode rather than redirecting telemetry to a fake endpoint.

The source package manifest and Xcode project reference the local vendor directory so the fix is reproducible. To refresh the vendor, fetch the selected official tag, reapply and review the actor, notification, telemetry, and model-only transport changes, run the policy tests and offline inference check, and update the commit and patch notes here. The project does not claim that this vendored compatibility patch is an upstream RunAnywhere change.

## Model-only transport

The shared HTTP adapter stays registered because model planning needs it. In local-only mode its RequestSnapshot permits only body-free GET/HEAD requests to the exact Qwen artifact URL. Redirects must originate from that approved request and use HTTPS Hugging Face/Xet storage hosts. The same policy is tested from the actual source file by Tests/NetworkPolicyTests.swift. Optional download notifications are disabled in local-only mode.

## Native entry points

The app linker explicitly retains the 133 native entry points listed in NATIVE-SYMBOLS.txt and exports them for the SDK's dynamic lookup. Using all_load instead pulled unsupported optional backend registration objects. Both Package.swift and the Xcode target contain the explicit retention flags.

In local-only mode, Device.persistentId returns a process-cached ephemeral UUID instead of querying Keychain. This covers both SDK initialization entry points. A live Mac stack sample showed that the latter could block startup in SecItemCopyMatching after rebuilding the app. The normal non-local-only path retains the SDK’s persistent ID behavior; Keychain settings and access controls are unchanged.


In local-only mode on macOS, model storage now uses `~/Library/Application Support/Fieldnotes` as its base rather than Documents. A repeated live stack sample showed `try_restore_model_manifest_by_id` waiting in a filesystem open beneath Documents. After copying the existing model into the dedicated Application Support cache, initialization and two sequential inference runs completed. iOS storage is unchanged. Existing Documents files were retained. Other Mac installs using the old location must copy their model directory or download the model once into the new cache.

# Local changes to RunAnywhere Swift SDK

This SDK source is based on RunAnywhere Swift SDK 0.20.24, upstream commit `f269ccd53f04b2fa2a4767f7264a40363b7ec74a`. Fieldnotes maintains the changes below; they are not an official RunAnywhere release. The upstream license is in [`LICENSE`](runanywhere-swift/LICENSE).

| SDK file | Fieldnotes change |
| --- | --- |
| `Sources/RunAnywhere/Features/TTS/Services/AudioPlaybackManager.swift` | Moves `AVAudioPlayerDelegate` conformance into an `@preconcurrency` extension so Swift 6.4 does not infer main-actor isolation for the lock-protected audio manager. |
| `Sources/RunAnywhere/Features/Downloads/DownloadNotifier.swift` | Skips optional local notifications when there is no app bundle identifier, allowing command-line and SwiftPM smoke hosts to download models. |
| `Sources/RunAnywhere/Foundation/Bridge/CppBridge.swift` | In `RUNANYWHERE_SWIFT_LOCAL_ONLY=1` mode, skips telemetry sink setup and device-registration callbacks. |
| `Sources/RunAnywhere/HttpTransport/URLSessionHttpTransport.swift` | Applies the local-only request policy to model artifact requests and their redirects. |
| `Sources/RunAnywhere/HttpTransport/FieldnotesNetworkPolicy.swift` | Adds the Fieldnotes policy: body-free GET/HEAD to the pinned Qwen artifact, with HTTPS redirects limited to Hugging Face/Xet storage hosts. |
| `Sources/RunAnywhere/Public/RunAnywhere.swift` | Uses a process-cached ephemeral device ID in local-only mode and stores the macOS model cache under Application Support to avoid observed startup stalls. |

[`Tests/NetworkPolicyTests.swift`](../Tests/NetworkPolicyTests.swift) tests the request policy. [SDK compatibility notes](../docs/SDK-COMPATIBILITY.md) explain the changes and model-cache migration. Existing SDK file notices remain in place. Read the full SDK license before using or redistributing the SDK or these modifications.

# Third-party software and notices

## RunAnywhere Swift SDK

This project includes source from RunAnywhere Swift SDK 0.20.24 (upstream commit `f269ccd53f04b2fa2a4767f7264a40363b7ec74a`) under `Vendor/runanywhere-swift`. The complete supplied license is preserved at `Vendor/runanywhere-swift/LICENSE`. It is a RunAnywhere license with a free-use grant subject to stated user and use conditions, followed by Apache License 2.0 terms. Read the full license before use or redistribution. This project does not relicense the SDK as Apache-2.0.

The vendored SDK has local Fieldnotes patches. The complete file-by-file list of local SDK changes is in [Vendor/FIELDNOTES-MODIFICATIONS.md](Vendor/FIELDNOTES-MODIFICATIONS.md); additional compatibility context is in [docs/SDK-COMPATIBILITY.md](docs/SDK-COMPATIBILITY.md). In brief, the changes adjust Swift 6 actor compatibility, skip optional download notifications without an app bundle, skip SDK telemetry/device registration in local-only mode, and restrict HTTP requests in local-only mode. Modified files retain their upstream notices. The SDK is not presented as an official RunAnywhere release.

RunAnywhere's package manifest downloads native binary dependencies from its configured releases at build time. These binaries are not checked into this repository; their license and checksum metadata remain in the SDK package manifest and resolution files.

## Other dependencies

Swift Package Manager pins exact dependency versions in `Package.resolved`. Each dependency remains under its own license as declared by its upstream package. See package manifests and upstream license files when using or redistributing those dependencies.

## Model

Qwen2.5 3B Instruct Q4_K_M weights are not included. The app obtains the model separately at first run. Review the model publisher's license and acceptable-use terms before distributing or deploying it.

# Fieldnotes

A SwiftUI sample that turns a meeting note into reviewable action candidates. Each candidate links back to its exact source passage so you can check what the model selected before sharing.

[![Fieldnotes showing a highlighted source sentence beside three action candidates](media/preview.png)](media/demo.mp4)

**[Watch the 21-second demo](media/demo.mp4)** · **[Read the technical write-up](docs/WRITEUP.md)** · [Validation and known limits](docs/VALIDATION.md)

The demo uses genuine app captures with an edited cursor and a shortened processing wait. It explains the workflow; it is not a speed benchmark.

## What it demonstrates

- RunAnywhere Swift SDK 0.20.24 with llama.cpp
- Qwen2.5 3B Instruct, Q4_K_M (about 1.93 GB)
- Per-passage classification with English-language safeguards
- Verbatim source wording, expandable source review and independent action selection
- Local-only SDK initialization and an allowlist for model artifact downloads

The model proposes candidates; it does not establish that a sentence is a commitment. Review each suggestion. The language rules are English-specific and incomplete.

## Run on macOS

Requires macOS 14.5+, an Xcode toolchain with Swift 6.2+, and an Apple Silicon Mac for the tested local model path. From this directory:

```sh
swift build --build-system native
./scripts/package-mac.sh
open dist/Fieldnotes.app
```

The initial build resolves the vendored RunAnywhere package and its native binary dependencies. The first **Find actions** run downloads the model; allow about 1.93 GB plus room for temporary download files. Keep network access on until the model is cached. Later inference uses the local model.

## Run on iPhone

Requires iOS 17.5+ and Xcode. Open `Fieldnotes.xcodeproj`, choose the `Fieldnotes` scheme and a connected iPhone, set your Apple development team under **Signing & Capabilities**, then run. Change the bundle identifier if Xcode reports that it is already in use. A network connection is needed for the first model download.

The confirmed iPhone 15 Pro Max passed a three-action Maya-note smoke test in 3.61 seconds excluding model loading. llama.cpp reported all 37 layers offloaded to Metal. This is one smoke case, not a full phone benchmark. No Apple Neural Engine or Qualcomm NPU result is claimed. [Sanitized device evidence](docs/evidence/iphone-smoke.txt). Airplane-mode behavior on the phone, sustained thermal/memory use, and exhaustive accessibility remain unverified.

## Checks and evaluation

Run the focused parser/language, evidence, and network-policy checks from the project root:

```sh
sh scripts/check-selection.sh
sh scripts/check-evidence.sh
sh scripts/check-network.sh
```

All 44 passed in the recorded 5 November check. The current hybrid pipeline matched source references in 31 of 32 small synthetic regression cases. The remaining miss is an implicit procurement follow-up. The first 24 cases informed implementation, so this score is not an unbiased estimate of general accuracy. Read [the evaluation notes](docs/EVALUATION.md) before interpreting it.

## Privacy and downloads

The checked-in SDK changes skip telemetry and device registration in local-only mode. Model download still makes an outbound request for the model artifact. No credentials or model weights are included in this repository. See [SDK compatibility notes](docs/SDK-COMPATIBILITY.md) for the patches and [third-party notices](THIRD_PARTY.md) for licensing.

## License

No license has been assigned to the Fieldnotes application code in this repository. The vendored RunAnywhere SDK retains its own license at `Vendor/runanywhere-swift/LICENSE`; its terms also govern that SDK code and modifications to it. Other package dependencies retain their respective licenses. See [THIRD_PARTY.md](THIRD_PARTY.md). Do not assume the application code is licensed under Apache-2.0.

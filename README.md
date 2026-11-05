# Fieldnotes

A SwiftUI sample that finds possible action items in meeting notes and lets you check each one against the original text before sharing it.

[![Fieldnotes showing a highlighted source sentence beside three action candidates](media/preview.png)](media/demo.mp4)

[Watch the 21-second demo](media/demo.mp4) · [Read the technical write-up](docs/WRITEUP.md) · [Validation and known limits](docs/VALIDATION.md)

The video skips part of the wait.

## How it works

Paste a note, find the tasks, and click any suggestion to see the sentence it came from. Select the ones you want to share.

Fieldnotes runs Qwen2.5 3B Instruct on your Mac or iPhone using RunAnywhere’s Swift SDK and llama.cpp. It checks each passage with the full note as context and uses a few English-language rules to catch requests and offers the model misses. You still need to review the suggestions.

## Run on macOS

Requires macOS 14.5+, an Xcode toolchain with Swift 6.2+, and an Apple Silicon Mac. From this directory:

```sh
swift build --build-system native
./scripts/package-mac.sh
open dist/Fieldnotes.app
```

The RunAnywhere SDK source is included in this repo. The first build downloads its dependencies. The first time you choose **Find actions**, the app downloads the 1.93 GB model (with extra space needed while downloading). Keep the Mac online for setup. Once cached, the model runs locally.

## Run on iPhone

Requires iOS 17.5+ and Xcode. Open `Fieldnotes.xcodeproj`, choose the `Fieldnotes` scheme and a connected iPhone, set your Apple development team under **Signing & Capabilities**, then run. Change the bundle identifier if Xcode reports that it is already in use. A network connection is needed for the first model download.

In one test on my iPhone 15 Pro Max, it found all three tasks in the Maya note in 3.61 seconds after the model loaded. [Test results and limitations](docs/VALIDATION.md).

## Checks and evaluation

Run the checks from the project root:

```sh
sh scripts/check-selection.sh
sh scripts/check-evidence.sh
sh scripts/check-network.sh
```

All 44 checks passed on 5 November. The extractor matched the expected passages in 31 of 32 test notes. It missed an implied procurement follow-up. These are made-up notes; the first 24 were used during development. See [the evaluation notes](docs/EVALUATION.md) for the details.

## Privacy and downloads

The app connects to download the model, then processes notes on your device. I changed the SDK to turn off telemetry and device registration in local-only mode. Model files are downloaded separately. See [SDK compatibility notes](docs/SDK-COMPATIBILITY.md) and [third-party notices](THIRD_PARTY.md).

## License

I haven’t assigned a license to the Fieldnotes app code. The RunAnywhere SDK and its local changes have their own terms in `Vendor/runanywhere-swift/LICENSE`; other dependencies keep their upstream licenses. See [THIRD_PARTY.md](THIRD_PARTY.md). Apache-2.0 does not automatically apply to the app code.

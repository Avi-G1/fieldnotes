# Validation

## Current evidence

- The SwiftUI app builds for macOS and iOS with the pinned SDK package and required native dependencies.
- The three-action Maya note passed on a physical iPhone 15 Pro Max. Extraction took 3.61 seconds after model load. llama.cpp reported all 37 layers offloaded to the Metal GPU. Sanitized runtime evidence is in [evidence/iphone-smoke.txt](evidence/iphone-smoke.txt).
- The small synthetic set matched 31 of 32 cases. The missed case is an implicit procurement follow-up. The first 24 cases informed implementation, so this development regression score does not estimate accuracy on new notes. See [the evaluation notes](EVALUATION.md).
- The parser/language, evidence-validation, and network-policy scripts passed 44 focused checks. Those checks do not measure semantic accuracy.

## Release packaging check — 5 November 2026

The staged repository built with SwiftPM on macOS using cached dependencies. The packaging script assembled the development app, and ad-hoc code-signature verification passed. The build still emits SDK and Swift concurrency warnings. I checked the public documentation links locally. The repository excludes model weights, build products, and private application notes.

## Limits

The phone result covers one smoke case. Timings exclude the initial model download and load. The recorded backend is llama.cpp with Metal GPU offload; there is no NPU result. Airplane Mode operation, interrupted-download recovery, sustained thermal and memory behavior, exhaustive accessibility, and accuracy on varied real notes remain untested.

The demo uses app screenshots and an animated cursor. Part of the wait is cut, so use the recorded test times above to judge speed. The [technical write-up](WRITEUP.md) explains the design and tradeoffs.

# Validation

## Current evidence

- The SwiftUI app builds for macOS and iOS with the pinned SDK package and its required native binary dependencies.
- The three-action Maya note passed on a physical iPhone 15 Pro Max. Extraction took 3.61 seconds after the model was loaded; llama.cpp reported 37/37 layers offloaded to Metal. The sanitized runtime evidence is in [evidence/iphone-smoke.txt](evidence/iphone-smoke.txt).
- The small synthetic reference set matched 31 of 32 cases. The remaining miss is an implicit procurement follow-up. The first 24 cases informed implementation, so this is a development regression score, not an unbiased accuracy estimate. See [the evaluation notes](EVALUATION.md).
- The parser/language, evidence-validation, and network-policy scripts report 44 passing focused checks. These checks do not measure semantic accuracy.

## Release packaging check — 5 November 2026

The staged repository passed a macOS SwiftPM build using cached dependencies. The packaging script assembled the development app and passed ad-hoc code-signature verification. The build still emits SDK and Swift concurrency warnings; this is not a warning-free build. All public documentation links were checked locally. Model weights, build products, and private application notes are excluded.

## Limits

This is a single physical-device smoke case, not a full phone benchmark. Timings exclude initial model download and loading. No NPU result is claimed: the recorded backend is llama.cpp with Metal GPU offload. Airplane-mode operation, interrupted-download recovery, sustained thermal/memory behavior, exhaustive accessibility, and broad real-world extraction accuracy have not been established.

The demo video is an edited walkthrough with genuine app captures. Its cursor and processing wait are edited; it does not establish live latency. Consult [the technical write-up](WRITEUP.md) for the system design and its tradeoffs.

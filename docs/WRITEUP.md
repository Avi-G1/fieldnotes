# When a correct quote still gives the wrong action

Fieldnotes turns meeting notes into action candidates. Each candidate keeps the exact source sentence so a person can check it before sharing. While testing a short note about an onboarding flow, I found a weakness that the quote alone could not solve: the model sometimes skipped Maya’s offer to send a revision by Thursday.

Source links establish provenance, but cannot show whether the extractor found every task or interpreted the sentence correctly. That distinction shaped the implementation.

## Make selection the model’s job

The first versions used a single request to produce a list of tasks. A small model could omit later commitments. A free-form response also gave the model room to rewrite tasks or add detail.

Fieldnotes now splits a note into punctuation-delimited passages. For each passage, it asks the model to classify that target while supplying the full numbered note as context. The model returns an index, not new task wording. The app validates the response shape and range, then copies selected passage text into the action and source fields.

Traceable output can still select the wrong sentence. Copying it exactly would preserve the mistake as a bad action candidate.

## Use rules for clear English signals

The model can miss direct requests and reported offers, or select completed work and withdrawn suggestions. A small set of English-language rules now overrides its decision when wording gives a clear signal. Ambiguous passages stay with the model. Raw responses and rule overrides remain in the logs.

Model decisions and English-language rules both contribute to the hybrid result. The rules are incomplete: they depend on English phrasing, punctuation-based sentence splitting, and nearby references to cancellations or corrections. Multiple tasks in one sentence stay grouped as one item. More per-passage calls also add inference work.

## Keep the failure in the report

The final regression set contains 32 synthetic examples. The expected source selections matched in 31 cases. The first 24 cases informed implementation; the eight additional cases matched in seven. The remaining miss was: “A follow-up with procurement is needed next week.”

That result shows how the implementation handles known examples. It says little about arbitrary meeting notes. The comparison checks selected source text against expected passages; it cannot replace semantic review or user testing.

The app also validates that the response contains legal indexes and that displayed task text and quotes come from the note. These checks catch malformed output and invented wording. They cannot prove that a sentence is actionable. Review remains part of the feature.

## Run it on a phone

Fieldnotes uses RunAnywhere Swift SDK 0.20.24 with llama.cpp and Qwen2.5 3B Instruct Q4_K_M in GGUF format. The model file is about 1.93 GB. Q4 quantization makes the weights smaller; it does not remove their memory cost or guarantee better task selection.

On a physical iPhone 15 Pro Max, the three-action Maya example completed in 3.61 seconds after model load. The log records all 37 llama.cpp layers offloaded to the Metal GPU. This is one smoke-test result; repeated timing trials have not been run. It provides no evidence of Apple Neural Engine or Qualcomm NPU use. Airplane Mode has not been verified on the current phone build, and the first model acquisition needs a network connection or local transfer.

The Mac demo shows note input, extraction, source review, and selection. It uses genuine app captures with edited cursor movement and a shortened processing wait, so it should not be used to infer latency. The [demo video](../media/demo.mp4) shows the workflow; the [repository README](../README.md) has the build steps, and [validation notes](VALIDATION.md) record test scope and remaining limits.

## What I’d test next

The known failure points to the next test: vary how people imply work without saying “I’ll do it,” then check whether rule changes recover those tasks without promoting status updates or tentative ideas. I would also run repeated timing and memory trials on the phone, then verify cached inference with Wi-Fi off.

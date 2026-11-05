# Why Fieldnotes missed Maya’s task

Fieldnotes pulls possible actions out of meeting notes and shows the source sentence beside each one. While testing a note about an onboarding flow, I noticed it missed Maya’s offer to send a revision by Thursday.

## Checking each passage

My first version asked the model for a list of tasks in one request. It sometimes missed commitments later in the note. Asking it to write the tasks also left room for it to change their meaning.

Now the app splits the note at sentence punctuation and asks the model whether each passage describes an action. It includes the full numbered note as context, then expects the passage number in response. The app checks that the number is valid and copies the original passage into the action and source fields.

## Adding English-language rules

The model still misses direct requests and reported offers. Sometimes it picks up completed work or a suggestion someone has withdrawn. I added a few English-language rules for clear cases, such as an offer or a correction. For less clear wording, the app uses the model’s decision. The logs record when a rule changes that decision.

The rules depend on English phrasing and sentence punctuation, and look for nearby cancellations or corrections. Two tasks in one sentence stay together. The app makes a separate model call for each passage.

## Testing 32 notes

The test set contains 32 made-up notes. The extractor matched the expected passages in 31. I used the first 24 during development. It passed seven of the eight additional tests. The miss was “A follow-up with procurement is needed next week.”

I still need to test it on real meeting notes. The app checks that passage numbers are valid and that actions and quotes use words from the note. Those checks catch invalid responses and invented wording, but can’t tell whether the sentence is a real commitment. People still need to review the suggestions.

## Running it on an iPhone

Fieldnotes uses RunAnywhere Swift SDK 0.20.24, llama.cpp, and Qwen2.5 3B Instruct Q4_K_M in GGUF format. The model file is about 1.93 GB. Q4 quantization shrinks the weights, but the model still needs memory and can still miss tasks.

On my iPhone 15 Pro Max, the three-action Maya example took 3.61 seconds after the model loaded. The log shows all 37 llama.cpp layers running on the Metal GPU. I haven’t run repeated timing trials or tested Airplane Mode on this build. The app needs a network connection for the first model download.

[Watch the demo](../media/demo.mp4) or [build it yourself](../README.md). The video skips part of the wait; [the test notes](VALIDATION.md) have the measured results.

## What I’d test next

Next I want to test more indirect ways people assign work without saying “I’ll do it.” I’ll check whether rules catch those cases without turning status updates or tentative ideas into tasks. I also want to repeat the phone timing, measure memory, and try cached inference with Wi-Fi off.

# Extraction contract

The model sees numbered source passages and returns only `{"lines":[1,2]}` (or an empty array). SourceSelection validates the shape, integer indexes, uniqueness, and bounds. The app copies those passages into task/quote pairs, with owner/deadline null. The model never supplies new task wording or quotations in the shipped flow.

GroundedEvaluation validates the resulting action envelope: nonempty tasks, exact source quotes, task wording present in the quote, and any nonnull metadata present in that quote. It does not establish semantic entailment. A copied status update can still be an incorrect action candidate.

Run `sh scripts/check-evidence.sh` and `sh scripts/check-selection.sh` from the project root. See docs/VALIDATION.md for real inference results and semantic review.

# Checking extracted tasks

The model receives numbered source passages and returns only `{"lines":[1,2]}` or `{"lines":[]}`. SourceSelection checks the response shape, integer indexes, duplicates, and bounds. The app copies the selected passages into task/quote pairs and sets owner and deadline to `null`. In the shipped flow, the model cannot write task text or quotes.

GroundedEvaluation checks the returned JSON: tasks must be nonempty, quotes must match the source, task wording must appear in the quote, and any non-null metadata must appear there too. These checks cannot tell whether a sentence describes a task. The app could still select a status update by mistake.

From the project root, run `sh scripts/check-evidence.sh` and `sh scripts/check-selection.sh`. See [validation notes](../docs/VALIDATION.md) for model results and their limits.

# Fieldnotes evaluation protocol

The extractor combines a model with English-language rules. [Validation notes](VALIDATION.md) include the Mac results and the physical-phone test. The iPhone 15 Pro Max passed one smoke test. A full phone benchmark and an Airplane Mode check are still to come.

## Reproduce the current regression report

The set has 32 synthetic cases: ten in `fixtures.json`, eight in `holdout.json`, six in `reported-offers.json`, and eight in `additional-validation.json`. The first 24 informed implementation, so the full set is neither a production accuracy estimate nor an untouched holdout.

From the project root:

```sh
python3 - <<'PY'
import json
from pathlib import Path
names = ['fixtures.json', 'holdout.json', 'reported-offers.json', 'additional-validation.json']
cases = [case for name in names for case in json.loads((Path('Evaluation') / name).read_text())]
Path('/tmp/fieldnotes-fixtures.json').write_text(json.dumps(cases, indent=2))
PY
python3 scripts/score-extraction.py /tmp/fieldnotes-fixtures.json docs/results-hybrid.json
```

This command rescores saved outputs without rerunning the model. It should report 31/32 passes and exit with status 1 because `fresh-implicit` still fails. On 5 November, rescoring reproduced the saved report exactly. The comparison normalizes punctuation and whitespace, then checks whether each expected quote appears in the actual quote. Review the source/output pairs too.

To generate new results with a cached model, run the packaged binary with `--evaluate /tmp/fieldnotes-fixtures.json --results /tmp/fieldnotes-results.json`, then score that file. Keep the raw responses and any rule overrides. You may need to download and load the model first.

Focused checks:

```sh
sh scripts/check-selection.sh
sh scripts/check-evidence.sh
sh scripts/check-network.sh
```

These run 15 parser cases, eight language cases, ten evidence checks, and 11 network-policy checks. All 44 passed on 5 November. These checks cover specific examples; accuracy on varied meeting notes needs separate evaluation.

## Review rubric

For each result, check that it captures a real action, preserves uncertainty, excludes withdrawn or completed work, and keeps the source wording. A matching quote shows where the words came from; it cannot tell you whether they represent a commitment. Owners and dates remain in the source passage instead of being inferred into separate fields.

The pipeline still misses this implicit task: “A follow-up with procurement is needed next week.” It also keeps multiple tasks in one passage as a single selectable item.

## Timing and device scope

Total extraction time covers per-passage classification and final selection. It excludes the initial download and model load. It does not measure TTFT, token throughput, or cold-start latency. A note with multiple passages triggers multiple inference requests.

In the saved 32-case Mac run, median total extraction took 3.575 seconds; the slowest case took 7.09 seconds. Each case used a different input, so these are not repeated trials. The Maya smoke test on the physical iPhone 15 Pro Max took 3.61 seconds after model load, with Metal GPU offload recorded. One run cannot establish full-suite phone performance, sustained memory use, or thermal stability.

The Mac demo shortens the processing wait. It cannot support speed claims.

## Further phone measurements

For further phone tests, record the device and OS, SDK, model and quantization, backend, power mode, load time, and repeated extraction results. After caching the model, test Airplane Mode with Wi-Fi off, including after force-quitting and relaunching the app. Keep failed runs, memory terminations, and heat observations. Device hardware alone does not show that inference used an NPU.

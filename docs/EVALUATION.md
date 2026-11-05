# Fieldnotes evaluation protocol

The current extractor uses a model plus English-language rules. Mac results and physical-phone evidence are recorded in [VALIDATION.md](VALIDATION.md). A physical iPhone 15 Pro Max smoke test passed; a full phone benchmark and airplane-mode check remain outstanding.

## Reproduce the current regression report

There are 32 synthetic cases: ten in `fixtures.json`, eight in `holdout.json`, six in `reported-offers.json`, and eight in `additional-validation.json`. The first 24 informed implementation. Do not describe this as a production accuracy estimate or an untouched 32-case holdout.

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

This rescores saved outputs; it does not rerun the model. It should report 31/32 passes and exit with status 1 because `fresh-implicit` remains a failure. Re-scoring on 5 November reproduced the saved report exactly. The comparison normalizes punctuation and whitespace, then matches expected quote text inside actual quotes; inspect the source/output pairs as well.

To generate new results with a cached model, run the packaged binary with `--evaluate /tmp/fieldnotes-fixtures.json --results /tmp/fieldnotes-results.json`, then score that new file. Preserve the raw responses and any rule overrides. Model download/load may be required before the run.

Focused checks:

```sh
sh scripts/check-selection.sh
sh scripts/check-evidence.sh
sh scripts/check-network.sh
```

These cover 15 parser cases, eight language cases, ten evidence checks and 11 network-policy checks. All 44 passed again on 5 November. They do not establish general semantic accuracy.

## Review rubric

Check whether each result captures a real action, preserves uncertainty, excludes withdrawn or completed work, and retains exact source wording. A matching quote establishes where the words came from, not whether they represent a commitment. Owners and dates stay in source passages rather than being inferred into separate fields.

The retained failure is “A follow-up with procurement is needed next week.” The current model/rules pipeline omitted this implicit task. Multiple tasks within one passage also remain one selectable item.

## Timing and device scope

Total extraction time covers per-passage classification and final selection. It excludes initial download and model loading. It is not TTFT, token throughput, or cold-start latency. The current pipeline performs more than one inference request for a multi-passage note.

The stored 32-case Mac run has a median total extraction time of 3.575 seconds and a maximum of 7.09 seconds across different inputs. This is not a repeated-trial benchmark. The physical iPhone 15 Pro Max Maya smoke case completed in 3.61 seconds excluding load, with Metal GPU offload recorded. That single result does not establish full-suite phone performance, sustained memory behavior, or thermal stability.

The edited Mac video shortens the processing wait. Do not derive speed claims from it.

## Further phone measurements

Record device/OS, SDK, model/quantization, actual backend, power mode, load time and repeated extraction results. Test Airplane Mode with Wi-Fi off after caching the model, including force-quit/relaunch. Retain failed runs, memory terminations, and heat observations. Do not infer NPU use from the device hardware.

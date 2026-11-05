#!/usr/bin/env python3
"""Compare selected source passages with fixture references; not a quality claim beyond this set."""
import json
import re
import sys

fixtures = {x['id']: x for x in json.load(open(sys.argv[1]))}
runs = json.load(open(sys.argv[2]))
def normalized(s):
    return re.sub(r'\s+', ' ', s.strip().rstrip('.!?').replace('’', "'")).casefold()
rows = []
for run in runs:
    expected = [normalized(x['quote']) for x in fixtures[run['id']]['expected']['actions']]
    actual = [normalized(x['quote']) for x in run['actualActions']]
    remaining = list(actual)
    missed = []
    for quote in expected:
        match = next((x for x in remaining if quote in x), None)
        if match is None:
            missed.append(quote)
        else:
            remaining.remove(match)
    rows.append(dict(id=run['id'], passed=not missed and not remaining and not run.get('error'),
                     missed=missed, unexpected=remaining, error=run.get('error')))
report = dict(passed=sum(x['passed'] for x in rows), total=len(fixtures), completed=len(runs), cases=rows)
print(json.dumps(report, indent=2))
if len(runs) != len(fixtures) or not all(x['passed'] for x in rows):
    sys.exit(1)

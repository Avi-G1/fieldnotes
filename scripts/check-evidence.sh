#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
SCRATCH="${TMPDIR:-/tmp}/fieldnotes-checks"
mkdir -p "$SCRATCH"
swiftc -module-cache-path "$SCRATCH/modules" Evaluation/GroundedEvaluation.swift Tests/GroundedEvaluationTests.swift -o "$SCRATCH/checks"
"$SCRATCH/checks"

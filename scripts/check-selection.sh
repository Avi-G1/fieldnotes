#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODULE_CACHE=${TMPDIR:-/tmp}/fieldnotes-swift-module-cache
BIN=${TMPDIR:-/tmp}/fieldnotes-selection-tests
mkdir -p "$MODULE_CACHE"
swiftc -module-cache-path "$MODULE_CACHE" \
  "$ROOT/Evaluation/SourceSelection.swift" \
  "$ROOT/Tests/SourceSelectionTests.swift" \
  -o "$BIN"
"$BIN"

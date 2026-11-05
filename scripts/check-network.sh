#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
SCRATCH="${TMPDIR:-/tmp}/fieldnotes-checks"
mkdir -p "$SCRATCH"
swiftc -module-cache-path "$SCRATCH/modules" Vendor/runanywhere-swift/Sources/RunAnywhere/HttpTransport/FieldnotesNetworkPolicy.swift Tests/NetworkPolicyTests.swift -o "$SCRATCH/network-checks"
"$SCRATCH/network-checks"

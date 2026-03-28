#!/bin/bash
# SessionStart hook — Terminal-Themes / XcodeColorTheory
#
# Runs `swift build` and `swift test` from the XcodeColorTheory package directory
# so compiler errors surface at the start of every session rather than mid-edit.
#
# Requirements: macOS 14+ with Swift 6.0+ (Xcode 16+)
# Skips silently on Linux/CI environments where SwiftUI is unavailable.

set -euo pipefail

# Only run on macOS — the SwiftUI app cannot build on Linux.
if [[ "$(uname)" != "Darwin" ]]; then
    echo "session-start: not macOS — skipping Swift build/test"
    exit 0
fi

# Bail gracefully if swift is not on PATH (Xcode not installed or xcrun not set up).
if ! command -v swift &>/dev/null; then
    echo "session-start: swift not found — skipping build/test"
    echo "Install Xcode 16+ and run: sudo xcode-select --install"
    exit 0
fi

PACKAGE_DIR="${CLAUDE_PROJECT_DIR}/XcodeColorTheory"

if [[ ! -f "${PACKAGE_DIR}/Package.swift" ]]; then
    echo "session-start: Package.swift not found at ${PACKAGE_DIR} — skipping"
    exit 0
fi

echo "=== session-start: swift build ==="
swift build --package-path "${PACKAGE_DIR}" 2>&1

echo ""
echo "=== session-start: swift test ==="
swift test --package-path "${PACKAGE_DIR}" 2>&1

echo ""
echo "session-start: build and tests passed ✓"

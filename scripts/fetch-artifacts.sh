#!/bin/bash -e
# This script has been deprecated and now is a wrapper to call the new
# fetch_artifacts.py script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Wrapper to call the new fetch_artifacts.py script
python3 "$SCRIPT_DIR/fetch_artifacts.py" "$@"

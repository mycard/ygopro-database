#!/bin/bash

# Input SQLite database path
DB="$1"

# Locate sqlite3 binary
source ./scripts/check-sqlite3

# Run .dump and filter out noise
"$SQLITE3" "$DB" .dump | grep -v '^--' | grep -v '^PRAGMA'

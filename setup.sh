#!/bin/bash

set -e

# Attempt to find sqlite3, including environment override and local bin/
find_sqlite3() {
  if [ -n "$SQLITE3_BIN" ] && [ -x "$SQLITE3_BIN" ]; then
    echo "$SQLITE3_BIN"
    return 0
  fi

  if command -v sqlite3 >/dev/null 2>&1; then
    echo "sqlite3"
    return 0
  fi

  if command -v sqlite3.exe >/dev/null 2>&1; then
    echo "sqlite3.exe"
    return 0
  fi

  if [ -x "./bin/sqlite3" ]; then
    echo "./bin/sqlite3"
    return 0
  fi

  if [ -x "./bin/sqlite3.exe" ]; then
    echo "./bin/sqlite3.exe"
    return 0
  fi

  return 1
}

install_sqlite3_windows() {
  echo "🔍 sqlite3 not found — downloading for Windows..."

  mkdir -p bin

  ZIP_URL="https://sqlite.org/2025/sqlite-tools-win-x64-3490200.zip"
  ZIP_FILE="bin/sqlite3.zip"

  # Only download if the zip file or binaries aren't already there
  if ! [ -f "$ZIP_FILE" ] || ! find bin -iname "sqlite3.exe" | grep -q .; then
    echo "⬇️ Downloading SQLite tools..."
    curl -sL -o "$ZIP_FILE" "$ZIP_URL" || {
      echo "❌ Failed to download SQLite zip from $ZIP_URL"
      exit 1
    }

    echo "📦 Extracting..."
    unzip -o "$ZIP_FILE" -d bin || {
      echo "❌ Failed to unzip SQLite tools"
      exit 1
    }
  else
    echo "✅ sqlite3 already exists in bin/, skipping download"
  fi
}

# --- Main logic ---

SQLITE3_PATH=$(find_sqlite3)

if [ -z "$SQLITE3_PATH" ]; then
  UNAME=$(uname | tr '[:upper:]' '[:lower:]')

  if echo "$UNAME" | grep -qi "mingw\\|msys\\|cygwin"; then
    install_sqlite3_windows
    SQLITE3_PATH=$(find_sqlite3)
  else
    echo "❌ sqlite3 not found in PATH or ./bin/"
    echo "Please install sqlite3 manually (e.g., via apt, brew, or your package manager)."
    exit 1
  fi
fi

echo "✅ Using sqlite3: $SQLITE3_PATH"
export SQLITE3_BIN="$SQLITE3_PATH"

# --- Git configuration ---

git config merge.sqlite-merge.name "SQLite dump merge"
git config merge.sqlite-merge.driver "scripts/sqlite-merge.sh %O %A %B %L %P"

git config diff.sqlite-diff.textconv "scripts/sqlite-diff.sh"
git config diff.sqlite-diff.prompt false

echo "✅ Git merge & diff drivers configured successfully."

#!/bin/bash

# Locate sqlite3 binary
source ./scripts/check-sqlite3

BASE="$1"
OURS="$2"
THEIRS="$3"
RESULT="$2"
FILE_PATH="$5"
CONFLICT_FILE="$FILE_PATH.sql"

TMPDIR=$(mktemp -d) || exit 1

# 手动清理函数
cleanup() {
  rm -rf "$TMPDIR"
}
# 不用 trap，因为 sh 没有 EXIT trap，靠手动调用

"$SQLITE3" "$BASE"   .dump > "$TMPDIR/base.sql"   || { cleanup; exit 1; }
"$SQLITE3" "$OURS"   .dump > "$TMPDIR/ours.sql"   || { cleanup; exit 1; }
"$SQLITE3" "$THEIRS" .dump > "$TMPDIR/theirs.sql" || { cleanup; exit 1; }

git merge-file -p "$TMPDIR/ours.sql" "$TMPDIR/base.sql" "$TMPDIR/theirs.sql" > "$TMPDIR/merged.sql"
MERGE_EXIT_CODE=$?

if grep '^<<<<<<<' "$TMPDIR/merged.sql" >/dev/null; then
    echo "❌ Merge conflict detected. Please resolve:"
    echo "   --> $CONFLICT_FILE"
    cp "$TMPDIR/merged.sql" "$CONFLICT_FILE"
    cleanup
    exit 1  # 保留冲突文件，人工处理，故不 cleanup
fi

rm -f "$RESULT"
"$SQLITE3" "$RESULT" < "$TMPDIR/merged.sql" || {
    echo "❌ Failed to import merged SQL"
    echo "   --> $CONFLICT_FILE"
    cp "$TMPDIR/merged.sql" "$CONFLICT_FILE"
    cleanup
    exit 1
}

echo "✅ Merged successfully to $FILE_PATH"
cleanup
exit 0

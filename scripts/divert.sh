#!/bin/bash

# Locate "$SQLITE3" binary
source ./scripts/check-sqlite3

mkdir -p diverted
rm -rf diverted/*

# Unicode codepoints for ① - ⑳
circle_nums=(9312 9313 9314 9315 9316 9317 9318 9319 9320 9321 9322 9323 9324 9325 9326 9327 9328 9329 9330)

for locale in $(ls -1 locales); do
  echo "Processing $locale"
  mkdir -p diverted/$locale-nonewline diverted/$locale-newline
  cp -rf locales/$locale/cards.cdb diverted/$locale-nonewline/cards.cdb
  cp -rf locales/$locale/cards.cdb diverted/$locale-newline/cards.cdb

  if [[ "$locale" == "zh-CN" ]]; then
    sql=""
    for codepoint in "${circle_nums[@]}"; do
      sql="$sql UPDATE texts SET desc = REPLACE(desc, '。' || char(13) || char(10) || char(${codepoint}), '。' || char(${codepoint}));"
      sql="$sql UPDATE texts SET desc = REPLACE(desc, '。' || char(10) || char(${codepoint}), '。' || char(${codepoint}));"
      sql="$sql UPDATE texts SET desc = REPLACE(desc, '。' || char(13) || char(${codepoint}), '。' || char(${codepoint}));"
    done
    "$SQLITE3" diverted/$locale-nonewline/cards.cdb "$sql"
  else
    "$SQLITE3" diverted/$locale-nonewline/cards.cdb "
      -- 1. 标记所有换行
      UPDATE texts SET desc = REPLACE(REPLACE(REPLACE(desc,
        char(13) || char(10), '__RN__'),
        char(10), '__N__'),
        char(13), '__R__');

      -- 2. 保留结构性换行（前换行）
      UPDATE texts SET desc = REPLACE(desc, '__RN__---', '__KEEP_NL_RN__---');
      UPDATE texts SET desc = REPLACE(desc, '__N__---', '__KEEP_NL_N__---');
      UPDATE texts SET desc = REPLACE(desc, '__R__---', '__KEEP_NL_R__---');

      UPDATE texts SET desc = REPLACE(desc, '__RN__[', '__KEEP_NL_RN__[');
      UPDATE texts SET desc = REPLACE(desc, '__N__[', '__KEEP_NL_N__[');
      UPDATE texts SET desc = REPLACE(desc, '__R__[', '__KEEP_NL_R__[');

      UPDATE texts SET desc = REPLACE(desc, '__RN__【', '__KEEP_NL_RN__【');
      UPDATE texts SET desc = REPLACE(desc, '__N__【', '__KEEP_NL_N__【');
      UPDATE texts SET desc = REPLACE(desc, '__R__【', '__KEEP_NL_R__【');

      -- 3. 保留结构性换行（后换行）
      UPDATE texts SET desc = REPLACE(desc, '---__RN__', '---__KEEP_NL_RN__');
      UPDATE texts SET desc = REPLACE(desc, '---__N__', '---__KEEP_NL_N__');
      UPDATE texts SET desc = REPLACE(desc, '---__R__', '---__KEEP_NL_R__');

      UPDATE texts SET desc = REPLACE(desc, ']__RN__', ']__KEEP_NL_RN__');
      UPDATE texts SET desc = REPLACE(desc, ']__N__', ']__KEEP_NL_N__');
      UPDATE texts SET desc = REPLACE(desc, ']__R__', ']__KEEP_NL_R__');

      UPDATE texts SET desc = REPLACE(desc, '】__RN__', '】__KEEP_NL_RN__');
      UPDATE texts SET desc = REPLACE(desc, '】__N__', '】__KEEP_NL_N__');
      UPDATE texts SET desc = REPLACE(desc, '】__R__', '】__KEEP_NL_R__');

      -- 4. 保留 \t 开头的换行（硬性换行）
      UPDATE texts SET desc = REPLACE(desc, char(9) || '__RN__', '__KEEP_NL_RN__');
      UPDATE texts SET desc = REPLACE(desc, char(9) || '__N__', '__KEEP_NL_N__');
      UPDATE texts SET desc = REPLACE(desc, char(9) || '__R__', '__KEEP_NL_R__');

      -- 5. 删除所有其余换行
      UPDATE texts SET desc = REPLACE(REPLACE(REPLACE(desc,
        '__RN__', ''), '__N__', ''), '__R__', '');

      -- 6. 恢复换行（按原始形式）
      UPDATE texts SET desc = REPLACE(desc, '__KEEP_NL_RN__', char(13) || char(10));
      UPDATE texts SET desc = REPLACE(desc, '__KEEP_NL_N__', char(10));
      UPDATE texts SET desc = REPLACE(desc, '__KEEP_NL_R__', char(13));
    "
  fi

  # newline version: just strip tab
  "$SQLITE3" diverted/$locale-newline/cards.cdb "UPDATE texts SET desc = REPLACE(desc, char(9), '');"
done

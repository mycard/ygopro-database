@echo off
setlocal enabledelayedexpansion

echo [INFO] Checking for sqlite3.exe...

REM 1. Try PATH
where sqlite3.exe >nul 2>nul
if %errorlevel%==0 (
    echo [OK] Found sqlite3.exe in PATH
    goto :gitconfig
)

REM 2. Try bin/sqlite3.exe
if exist "bin\sqlite3.exe" (
    echo [OK] Found bin\sqlite3.exe
    set "SQLITE3_BIN=bin\sqlite3.exe"
    goto :gitconfig
)

REM 3. Not found — download
echo [INFO] sqlite3 not found — downloading...

set "ZIP_URL=https://sqlite.org/2025/sqlite-tools-win-x64-3490200.zip"
set "ZIP_FILE=bin\sqlite3.zip"
set "UNZIP_DIR=bin"

if not exist bin (
    mkdir bin
)

echo [DOWNLOAD] Fetching SQLite...
curl -L -o "%ZIP_FILE%" "%ZIP_URL%"
if errorlevel 1 (
    echo [ERROR] Failed to download sqlite3 zip.
    exit /b 1
)

echo [UNZIP] Extracting...
unzip -o "%ZIP_FILE%" -d "%UNZIP_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to unzip SQLite tools.
    exit /b 1
)

if not exist "bin\sqlite3.exe" (
    echo [ERROR] sqlite3.exe not found after extraction.
    exit /b 1
)

set "SQLITE3_BIN=bin\sqlite3.exe"
echo [OK] sqlite3 installed to %SQLITE3_BIN%

:gitconfig
echo [CONFIG] Setting up Git merge driver...
git config merge.sqlite-merge.name "SQLite dump merge"
git config merge.sqlite-merge.driver "scripts/sqlite-merge.sh %%O %%A %%B %%L %%P"

echo [CONFIG] Setting up Git diff driver...
git config diff.sqlite-diff.textconv "scripts/sqlite-diff.sh"
git config diff.sqlite-diff.prompt false

echo [DONE] Git merge & diff drivers configured successfully.
exit /b 0

@echo off
setlocal enabledelayedexpansion

echo [INFO] Checking for sqlite3.exe...

:: 1. Check environment or local path
where sqlite3.exe >nul 2>nul
if %errorlevel%==0 (
    set "SQLITE3_BIN=sqlite3.exe"
    echo [OK] Found sqlite3.exe in PATH
) else if exist ".\bin\sqlite3.exe" (
    set "SQLITE3_BIN=bin\sqlite3.exe"
    echo [OK] Found sqlite3.exe in bin\
) else (
    echo [INFO] sqlite3.exe not found — downloading...
    mkdir bin >nul 2>nul

    set "SQLITE_URL=https://sqlite.org/2025/sqlite-tools-win-x64-3490200.zip"
    set "SQLITE_ZIP=bin\sqlite3.zip"

    if not exist "%SQLITE_ZIP%" (
        echo [DOWNLOAD] Downloading SQLite tools...
        powershell -Command "Invoke-WebRequest -Uri '%SQLITE_URL%' -OutFile '%SQLITE_ZIP%'" || goto :fail_download
    )

    echo [UNZIP] Extracting...
    powershell -Command "Expand-Archive -Path '%SQLITE_ZIP%' -DestinationPath 'bin' -Force" || goto :fail_unzip

    if not exist "bin\sqlite3.exe" (
        echo [ERROR] Failed to find sqlite3.exe after extraction.
        exit /b 1
    )

    set "SQLITE3_BIN=bin\sqlite3.exe"
    echo [OK] sqlite3 installed at: %SQLITE3_BIN%
)

:: 2. Git merge driver
echo [CONFIG] Setting up Git merge driver...
git config merge.sqlite-merge.name "SQLite dump merge"
git config merge.sqlite-merge.driver "scripts/sqlite-merge.sh %%O %%A %%B %%L %%P"

:: 3. Git diff driver
echo [CONFIG] Setting up Git diff driver...
git config diff.sqlite-diff.textconv "scripts/sqlite-diff.sh"
git config diff.sqlite-diff.prompt false

echo [DONE] Git merge & diff drivers configured successfully.
exit /b 0

:fail_download
echo [ERROR] Failed to download sqlite3.
exit /b 1

:fail_unzip
echo [ERROR] Failed to extract sqlite3.zip.
exit /b 1

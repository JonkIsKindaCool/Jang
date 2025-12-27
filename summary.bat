@echo off
setlocal enabledelayedexpansion

set "SRC_DIR=src"
set TOTAL_FILES=0
set TOTAL_LINES=0
set TOTAL_CLASSES=0

if not exist "%SRC_DIR%" (
    echo Error: Directory '%SRC_DIR%' does not exist.
    pause
    exit /b 1
)

echo Scanning Haxe files in %SRC_DIR%...
echo.

for /r "%SRC_DIR%" %%F in (*.hx) do (
    set /a TOTAL_FILES += 1
    
    set FILE_LINES=0
    set FILE_CLASSES=0
    
    for /f %%L in ('find /c /v "" ^< "%%F"') do set /a FILE_LINES=%%L
    
    for /f %%C in ('findstr /r /c:"^ *[a-zA-Z ]*class [a-zA-Z_][a-zA-Z0-9_]*" "%%F" ^| find /c /v ""') do set /a FILE_CLASSES=%%C
    
    set /a TOTAL_LINES += FILE_LINES
    set /a TOTAL_CLASSES += FILE_CLASSES
    
    echo %%~nxF: !FILE_LINES! lines, !FILE_CLASSES! classes
)

echo.
echo ====================================
echo Summary for %SRC_DIR%:
echo Total .hx files: %TOTAL_FILES%
echo Total lines: %TOTAL_LINES%
echo Total classes: %TOTAL_CLASSES%
echo ====================================

pause
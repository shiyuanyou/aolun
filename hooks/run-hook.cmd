@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "HOOK_NAME=%~1"

if "%HOOK_NAME%"=="" (
    echo Error: No hook name provided
    exit /b 1
)

if exist "%SCRIPT_DIR%%HOOK_NAME%.ps1" (
    where pwsh >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%%HOOK_NAME%.ps1" %2 %3 %4 %5 %6 %7 %8 %9
        exit /b %ERRORLEVEL%
    )
    where powershell >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%%HOOK_NAME%.ps1" %2 %3 %4 %5 %6 %7 %8 %9
        exit /b %ERRORLEVEL%
    )
)

where bash >nul 2>&1
if %ERRORLEVEL% equ 0 (
    bash "%SCRIPT_DIR%%HOOK_NAME%" %*
    exit /b %ERRORLEVEL%
)

where sh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    sh "%SCRIPT_DIR%%HOOK_NAME%" %*
    exit /b %ERRORLEVEL%
)

echo Error: No PowerShell, bash, or sh runtime found for hook "%HOOK_NAME%".
exit /b 1

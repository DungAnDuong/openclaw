@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title OpenClaw - Dang Khoi Dong...

:: ============================================================
:: start.bat - Script khoi dong OpenClaw Gateway
:: Phien ban: 2026.4.24
:: ============================================================

echo.
echo ============================================================
echo     OPENCLAW - KHOI DONG GATEWAY
echo ============================================================
echo.

:: --- Tao thu muc log ---
if not exist "logs" mkdir logs

:: Tao ten file log theo ngay
set "LOG_DATE=%date:~10,4%%date:~4,2%%date:~7,2%"
set "LOGFILE=logs\runtime_%LOG_DATE%.log"
set "PIDFILE=logs\openclaw.pid"

call :LOG "=== KHOI DONG OPENCLAW ==="
call :LOG "Thoi gian: %date% %time%"

:: ============================================================
:: BUOC 1: Kiem tra OpenClaw da cai dat chua
:: ============================================================
call :STEP "Kiem tra OpenClaw..."

openclaw --version >nul 2>&1
if errorlevel 1 (
    call :FAIL "OpenClaw chua duoc cai dat!"
    echo  Hay chay install.bat truoc.
    call :LOG "LOI: OpenClaw chua cai dat"
    pause
    exit /b 1
)

for /f "tokens=1" %%v in ('openclaw --version 2^>^&1') do set "OC_VERSION=%%v"
call :OK "OpenClaw: v%OC_VERSION%"
call :LOG "Phien ban: v%OC_VERSION%"

:: ============================================================
:: BUOC 2: Kiem tra file cau hinh
:: ============================================================
call :STEP "Doc cau hinh..."

if not exist "config\llm_config.json" (
    call :FAIL "Khong tim thay config\llm_config.json"
    echo  Hay chay install.bat truoc.
    pause
    exit /b 1
)

if not exist "config\app_config.json" (
    call :FAIL "Khong tim thay config\app_config.json"
    pause
    exit /b 1
)

:: Doc cong gateway tu app_config.json
for /f "delims=" %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$c = Get-Content 'config\app_config.json' | ConvertFrom-Json; Write-Output $c.gateway_port" 2^>^&1') do (
    set "GATEWAY_PORT=%%p"
)
if "%GATEWAY_PORT%"=="" set "GATEWAY_PORT=18789"

:: Doc verbose flag
for /f "delims=" %%v in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$c = Get-Content 'config\app_config.json' | ConvertFrom-Json; Write-Output $c.verbose" 2^>^&1') do (
    set "VERBOSE_FLAG=%%v"
)

set "EXTRA_FLAGS="
if /i "%VERBOSE_FLAG%"=="True" set "EXTRA_FLAGS=--verbose"

call :OK "Cong gateway: %GATEWAY_PORT%"
call :LOG "Cong gateway: %GATEWAY_PORT%, Verbose: %VERBOSE_FLAG%"

:: ============================================================
:: BUOC 3: Ap dung cau hinh tu config/ vao ~/.openclaw/openclaw.json
:: ============================================================
call :STEP "Ap dung cau hinh..."

powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\apply_openclaw_config.ps1" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    call :WARN "Co loi khi ap dung cau hinh. Xem %LOGFILE%"
    echo  Kiem tra config\llm_config.json - dam bao API key da duoc dien.
    pause
)

call :OK "Cau hinh da ap dung"

:: ============================================================
:: BUOC 4: Kiem tra process cu
:: ============================================================
call :STEP "Kiem tra trang thai..."

if exist "%PIDFILE%" (
    for /f "delims=" %%p in ('type "%PIDFILE%" 2^>nul') do set "OLD_PID=%%p"
    if not "!OLD_PID!"=="" (
        tasklist /FI "PID eq !OLD_PID!" 2>nul | find "!OLD_PID!" >nul 2>&1
        if not errorlevel 1 (
            call :WARN "OpenClaw dang chay (PID: !OLD_PID!). Dung truoc khi chay lai..."
            taskkill /PID !OLD_PID! /F >nul 2>&1
            timeout /t 2 /nobreak >nul
            call :LOG "Da dung process cu: PID !OLD_PID!"
        )
    )
    del "%PIDFILE%" >nul 2>&1
)

:: ============================================================
:: BUOC 5: Dat bien moi truong API key
:: ============================================================
call :STEP "Dat bien moi truong..."

:: Doc va dat API key tu llm_config.json
for /f "delims=" %%k in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$c = Get-Content 'config\llm_config.json' | ConvertFrom-Json; Write-Output $c.api_key" 2^>^&1') do (
    set "API_KEY=%%k"
)

for /f "delims=" %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$c = Get-Content 'config\llm_config.json' | ConvertFrom-Json; Write-Output $c.provider" 2^>^&1') do (
    set "LLM_PROVIDER=%%p"
)

if /i "%LLM_PROVIDER%"=="anthropic" set "ANTHROPIC_API_KEY=%API_KEY%"
if /i "%LLM_PROVIDER%"=="openai"    set "OPENAI_API_KEY=%API_KEY%"
if /i "%LLM_PROVIDER%"=="google"    set "GOOGLE_API_KEY=%API_KEY%"
if /i "%LLM_PROVIDER%"=="xai"       set "XAI_API_KEY=%API_KEY%"
if /i "%LLM_PROVIDER%"=="mistral"   set "MISTRAL_API_KEY=%API_KEY%"
if /i "%LLM_PROVIDER%"=="groq"      set "GROQ_API_KEY=%API_KEY%"

call :OK "Provider: %LLM_PROVIDER%"
call :LOG "Provider: %LLM_PROVIDER%"

:: ============================================================
:: BUOC 6: Khoi dong OpenClaw Gateway
:: ============================================================
call :STEP "Khoi dong Gateway tren cong %GATEWAY_PORT%..."

echo.
echo  ============================================================
echo   OpenClaw Gateway dang chay...
echo   Giao dien quan ly: http://127.0.0.1:%GATEWAY_PORT%
echo   Nhan Ctrl+C de dung
echo  ============================================================
echo.

call :LOG "Khoi dong: openclaw gateway --port %GATEWAY_PORT% %EXTRA_FLAGS%"

:: Chay openclaw va luu PID
start /b "" cmd /c "openclaw gateway --port %GATEWAY_PORT% %EXTRA_FLAGS% >> %LOGFILE% 2>&1 & echo !ERRORLEVEL!"

:: Doi mot chut de lay PID
timeout /t 2 /nobreak >nul

for /f "tokens=2" %%p in ('tasklist /FI "IMAGENAME eq node.exe" /FO LIST 2^>nul ^| find "PID:"') do (
    set "NEW_PID=%%p"
)

if not "!NEW_PID!"=="" (
    echo !NEW_PID! > "%PIDFILE%"
    call :LOG "OpenClaw chay voi PID: !NEW_PID!"
)

:: Chay truc tiep (foreground) de hien thi output
title OpenClaw - Dang Chay - Cong %GATEWAY_PORT%
openclaw gateway --port %GATEWAY_PORT% %EXTRA_FLAGS%

call :LOG "=== OPENCLAW DA DUNG ==="
echo.
echo  OpenClaw da dung.
echo.
goto :eof

:: ============================================================
:: CAC HAM HO TRO
:: ============================================================
:STEP
echo [....] %~1
call :LOG "BUOC: %~1"
goto :eof

:OK
echo [ OK ] %~1
call :LOG "OK: %~1"
goto :eof

:WARN
echo [WARN] %~1
call :LOG "CANH BAO: %~1"
goto :eof

:FAIL
echo [FAIL] %~1
call :LOG "LOI: %~1"
goto :eof

:LOG
echo %date% %time% - %~1 >> "%LOGFILE%" 2>nul
goto :eof

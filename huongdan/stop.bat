@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title OpenClaw - Dung Chuong Trinh

:: ============================================================
:: stop.bat - Script dung OpenClaw Gateway an toan
:: ============================================================

echo.
echo ============================================================
echo     OPENCLAW - DUNG CHUONG TRINH
echo ============================================================
echo.

if not exist "logs" mkdir logs
set "LOG_DATE=%date:~10,4%%date:~4,2%%date:~7,2%"
set "LOGFILE=logs\runtime_%LOG_DATE%.log"
set "PIDFILE=logs\openclaw.pid"

call :LOG "=== LENH DUNG OPENCLAW ==="
call :LOG "Thoi gian: %date% %time%"

set "FOUND=0"

:: ============================================================
:: BUOC 1: Thu dung theo PID da luu
:: ============================================================
if exist "%PIDFILE%" (
    for /f "delims=" %%p in ('type "%PIDFILE%" 2^>nul') do set "SAVED_PID=%%p"

    if not "!SAVED_PID!"=="" (
        echo [....] Kiem tra process PID: !SAVED_PID!...
        tasklist /FI "PID eq !SAVED_PID!" 2>nul | find "!SAVED_PID!" >nul 2>&1
        if not errorlevel 1 (
            echo [ OK ] Tim thay process PID: !SAVED_PID! - dang dung...
            taskkill /PID !SAVED_PID! /F >nul 2>&1
            if not errorlevel 1 (
                echo [ OK ] Da dung process PID: !SAVED_PID!
                call :LOG "Da dung PID: !SAVED_PID!"
                set "FOUND=1"
            )
        ) else (
            echo [INFO] PID !SAVED_PID! khong con chay.
        )
    )
    del "%PIDFILE%" >nul 2>&1
)

:: ============================================================
:: BUOC 2: Tim theo ten process (node.exe chay openclaw)
:: ============================================================
echo.
echo [....] Tim tat ca process OpenClaw...

:: Tim process node.exe co lien quan den openclaw
for /f "tokens=2" %%p in ('wmic process where "name='node.exe' and commandline like '%%openclaw%%'" get processid /value 2^>nul ^| find "="') do (
    set "NODE_PID=%%p"
    if not "!NODE_PID!"=="" (
        echo [ OK ] Tim thay node.exe PID: !NODE_PID! - dang dung...
        taskkill /PID !NODE_PID! /F >nul 2>&1
        if not errorlevel 1 (
            call :LOG "Da dung node.exe PID: !NODE_PID!"
            set "FOUND=1"
        )
    )
)

:: ============================================================
:: BUOC 3: Kiem tra cong gateway con mo khong
:: ============================================================
for /f "delims=" %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { $c = Get-Content 'config\app_config.json' | ConvertFrom-Json; Write-Output $c.gateway_port } catch { Write-Output 18789 }" 2^>^&1') do (
    set "GATEWAY_PORT=%%p"
)
if "%GATEWAY_PORT%"=="" set "GATEWAY_PORT=18789"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$c = Get-NetTCPConnection -LocalPort %GATEWAY_PORT% -State Listen -ErrorAction SilentlyContinue; if ($c) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue; Write-Host 'Da dung process tren cong %GATEWAY_PORT%' }" 2>nul
if not errorlevel 1 (
    set "FOUND=1"
    call :LOG "Da giai phong cong: %GATEWAY_PORT%"
)

:: ============================================================
:: BUOC 4: Don dep tai nguyen tam thoi
:: ============================================================
echo.
echo [....] Don dep tai nguyen tam...

:: Xoa file PID cu
if exist "%PIDFILE%" del "%PIDFILE%" >nul 2>&1

:: Xoa file lock neu co
if exist "logs\openclaw.lock" del "logs\openclaw.lock" >nul 2>&1

echo [ OK ] Don dep hoan thanh

:: ============================================================
:: KET QUA
:: ============================================================
echo.
if "!FOUND!"=="1" (
    echo ============================================================
    echo     OPENCLAW DA DUNG THANH CONG
    echo ============================================================
    call :LOG "=== DUNG THANH CONG ==="
) else (
    echo ============================================================
    echo     OPENCLAW KHONG DANG CHAY (hoac da dung tu truoc)
    echo ============================================================
    call :LOG "Khong tim thay process OpenClaw"
)

echo.
echo  Log da luu tai: %LOGFILE%
echo.
call :LOG "Thoi gian dung: %date% %time%"
timeout /t 3 /nobreak >nul
exit /b 0

:LOG
echo %date% %time% - %~1 >> "%LOGFILE%" 2>nul
goto :eof

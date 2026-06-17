@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title OpenClaw - Backup Du Lieu

:: ============================================================
:: backup.bat - Backup cau hinh va du lieu OpenClaw
:: ============================================================

echo.
echo ============================================================
echo     OPENCLAW - BACKUP DU LIEU
echo ============================================================
echo.

if not exist "logs" mkdir logs
if not exist "backups" mkdir backups

:: Tao ten thu muc backup theo timestamp
set "TS=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%"
set "TS=%TS: =0%"
set "BACKUP_DIR=backups\backup_%TS%"

set "LOGFILE=logs\backup_%TS%.log"
call :LOG "=== BAT DAU BACKUP ==="
call :LOG "Thoi gian: %date% %time%"
call :LOG "Thu muc backup: %BACKUP_DIR%"

echo [....] Tao thu muc backup: %BACKUP_DIR%
mkdir "%BACKUP_DIR%" 2>nul
if errorlevel 1 (
    echo [FAIL] Khong the tao thu muc backup!
    call :LOG "LOI: Khong tao duoc thu muc backup"
    pause
    exit /b 1
)
echo [ OK ] Thu muc backup da tao

:: ============================================================
:: BUOC 1: Backup thu muc config/
:: ============================================================
echo.
echo [....] Backup cau hinh (config/)...

if exist "config" (
    xcopy "config" "%BACKUP_DIR%\config\" /E /I /Q >nul 2>&1
    if errorlevel 1 (
        echo [WARN] Backup config that bai mot phan
        call :LOG "CANH BAO: Backup config khong hoan chinh"
    ) else (
        echo [ OK ] Backup config hoan thanh
        call :LOG "OK: Backup config/"
    )
) else (
    echo [WARN] Thu muc config/ khong ton tai
    call :LOG "CANH BAO: Thu muc config/ khong co"
)

:: ============================================================
:: BUOC 2: Backup thu muc data/
:: ============================================================
echo.
echo [....] Backup du lieu (data/)...

if exist "data" (
    xcopy "data" "%BACKUP_DIR%\data\" /E /I /Q >nul 2>&1
    echo [ OK ] Backup data hoan thanh
    call :LOG "OK: Backup data/"
) else (
    echo [INFO] Thu muc data/ rong hoac khong ton tai - bo qua
    call :LOG "INFO: Thu muc data/ khong co"
)

:: ============================================================
:: BUOC 3: Backup cau hinh OpenClaw goc (~/.openclaw/)
:: ============================================================
echo.
echo [....] Backup cau hinh he thong OpenClaw (~/.openclaw/)...

set "OC_CONFIG_DIR=%USERPROFILE%\.openclaw"
if exist "%OC_CONFIG_DIR%" (
    mkdir "%BACKUP_DIR%\openclaw-system" >nul 2>&1

    :: Chi backup cac file quan trong, bo qua node_modules
    if exist "%OC_CONFIG_DIR%\openclaw.json" (
        copy "%OC_CONFIG_DIR%\openclaw.json" "%BACKUP_DIR%\openclaw-system\" >nul 2>&1
        echo [ OK ] Backup openclaw.json
        call :LOG "OK: Backup openclaw.json"
    )

    if exist "%OC_CONFIG_DIR%\workspace" (
        xcopy "%OC_CONFIG_DIR%\workspace" "%BACKUP_DIR%\openclaw-system\workspace\" /E /I /Q /EXCLUDE:backup_exclude.txt >nul 2>&1
        echo [ OK ] Backup workspace
        call :LOG "OK: Backup workspace"
    )

    if exist "%OC_CONFIG_DIR%\store" (
        xcopy "%OC_CONFIG_DIR%\store" "%BACKUP_DIR%\openclaw-system\store\" /E /I /Q >nul 2>&1
        echo [ OK ] Backup store (danh sach xac thuc)
        call :LOG "OK: Backup store"
    )
) else (
    echo [INFO] Chua co cau hinh OpenClaw he thong - bo qua
    call :LOG "INFO: Khong tim thay %OC_CONFIG_DIR%"
)

:: ============================================================
:: BUOC 4: Tao file thong tin backup
:: ============================================================
echo.
echo [....] Ghi thong tin backup...

(
    echo OPENCLAW BACKUP INFO
    echo ====================
    echo Thoi gian: %date% %time%
    echo May tinh: %COMPUTERNAME%
    echo Nguoi dung: %USERNAME%
    echo.
    for /f "tokens=1" %%v in ('openclaw --version 2^>^&1') do echo Phien ban OpenClaw: v%%v
    for /f "tokens=1" %%v in ('node --version 2^>^&1') do echo Phien ban Node.js: %%v
    echo.
    echo Thu muc backup: %BACKUP_DIR%
) > "%BACKUP_DIR%\backup_info.txt" 2>nul

echo [ OK ] Thong tin backup da ghi

:: ============================================================
:: BUOC 5: Nen thu muc backup (neu co 7-Zip hoac tar)
:: ============================================================
echo.
echo [....] Nen backup...

:: Thu nen bang tar (co san trong Windows 10+)
tar -czf "%BACKUP_DIR%.tar.gz" "%BACKUP_DIR%" >nul 2>&1
if not errorlevel 1 (
    echo [ OK ] Da nen thanh: %BACKUP_DIR%.tar.gz
    call :LOG "OK: Da nen: %BACKUP_DIR%.tar.gz"
    :: Xoa thu muc goc sau khi nen thanh cong
    rmdir /S /Q "%BACKUP_DIR%" >nul 2>&1
    set "FINAL_BACKUP=%BACKUP_DIR%.tar.gz"
) else (
    echo [INFO] Khong the nen (giu nguyen thu muc)
    call :LOG "INFO: Giu nguyen thu muc khong nen"
    set "FINAL_BACKUP=%BACKUP_DIR%"
)

:: ============================================================
:: DON DEP BACKUP CU (giu lai 10 ban moi nhat)
:: ============================================================
echo.
echo [....] Don dep backup cu...

set "COUNT=0"
for /f "skip=10 delims=" %%f in ('dir /B /O-D "backups\backup_*" 2^>nul') do (
    del /Q "backups\%%f" >nul 2>&1
    rmdir /S /Q "backups\%%f" >nul 2>&1
    echo [INFO] Da xoa backup cu: %%f
    call :LOG "INFO: Xoa backup cu: %%f"
)

:: ============================================================
:: KET QUA
:: ============================================================
echo.
echo ============================================================
echo     BACKUP HOAN THANH THANH CONG!
echo ============================================================
echo.
echo  Luu tai: %FINAL_BACKUP%
echo  Log: %LOGFILE%
echo.
call :LOG "=== BACKUP HOAN THANH: %FINAL_BACKUP% ==="
timeout /t 3 /nobreak >nul
exit /b 0

:LOG
echo %date% %time% - %~1 >> "%LOGFILE%" 2>nul
goto :eof

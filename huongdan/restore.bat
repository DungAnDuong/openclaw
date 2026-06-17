@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title OpenClaw - Khoi Phuc Du Lieu

:: ============================================================
:: restore.bat - Khoi phuc cau hinh va du lieu tu backup
:: ============================================================

echo.
echo ============================================================
echo     OPENCLAW - KHOI PHUC DU LIEU
echo ============================================================
echo.

if not exist "logs" mkdir logs
set "LOG_DATE=%date:~10,4%%date:~4,2%%date:~7,2%"
set "LOGFILE=logs\restore_%LOG_DATE%.log"

call :LOG "=== BAT DAU KHOI PHUC ==="
call :LOG "Thoi gian: %date% %time%"

:: ============================================================
:: BUOC 1: Liet ke cac ban backup
:: ============================================================
if not exist "backups" (
    echo [FAIL] Thu muc backups/ khong ton tai!
    echo  Chua co backup nao duoc tao.
    pause
    exit /b 1
)

echo Danh sach cac ban backup:
echo.
echo  STT  Ten backup                          Kich thuoc
echo  ---  ----------------------------------  ----------

set "COUNT=0"
set "BACKUP_LIST="

:: Liet ke ca file .tar.gz va thu muc
for /f "delims=" %%f in ('dir /B /O-D "backups\backup_*" 2^>nul') do (
    set /a COUNT+=1
    set "BACKUP_!COUNT!=%%f"
    set "FULL_PATH=backups\%%f"

    :: Lay kich thuoc
    for %%s in ("backups\%%f") do set "FSIZE=%%~zs"
    if "!FSIZE!"=="" set "FSIZE=--"

    echo   !COUNT!.   %%f
    call :LOG "Backup !COUNT!: %%f"
)

if !COUNT!==0 (
    echo  [Khong co backup nao trong thu muc backups/]
    echo.
    echo  Hay chay backup.bat truoc de tao ban backup.
    call :LOG "Khong co backup nao"
    pause
    exit /b 1
)

echo.
echo  0.   THOAT - Khong khoi phuc

:: ============================================================
:: BUOC 2: Cho nguoi dung chon
:: ============================================================
echo.
set /p "CHOICE=Nhap so thu tu ban backup can khoi phuc (1-%COUNT%, hoac 0 de thoat): "

if "%CHOICE%"=="0" (
    echo  Huy bo khoi phuc.
    exit /b 0
)

:: Kiem tra input hop le
set /a CHOICE_NUM=%CHOICE% 2>nul
if !CHOICE_NUM! LSS 1 (
    echo [FAIL] Lua chon khong hop le!
    pause
    exit /b 1
)
if !CHOICE_NUM! GTR !COUNT! (
    echo [FAIL] So thu tu vuot qua danh sach!
    pause
    exit /b 1
)

set "SELECTED_BACKUP=!BACKUP_%CHOICE%!"
echo.
echo [....] Da chon: !SELECTED_BACKUP!
call :LOG "Nguoi dung chon: !SELECTED_BACKUP!"

:: Xac nhan truoc khi ghi de
echo.
echo [CANH BAO] Thao tac nay se GHI DE cau hinh hien tai!
set /p "CONFIRM=Ban co chac chan muon khoi phuc? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo  Huy bo khoi phuc.
    call :LOG "Nguoi dung huy bo"
    pause
    exit /b 0
)

:: ============================================================
:: BUOC 3: Giai nen neu la .tar.gz
:: ============================================================
set "RESTORE_DIR="
set "FULL_BACKUP_PATH=backups\!SELECTED_BACKUP!"

echo.
echo [....] Chuan bi phuc hoi...

:: Kiem tra la file nen hay thu muc
if "!SELECTED_BACKUP:~-7!"==".tar.gz" (
    echo [....] Giai nen backup...
    set "TEMP_EXTRACT=backups\_temp_restore"
    if exist "!TEMP_EXTRACT!" rmdir /S /Q "!TEMP_EXTRACT!" >nul 2>&1
    mkdir "!TEMP_EXTRACT!" >nul 2>&1
    tar -xzf "!FULL_BACKUP_PATH!" -C "!TEMP_EXTRACT!" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Khong the giai nen backup!
        call :LOG "LOI: Khong giai nen duoc: !FULL_BACKUP_PATH!"
        pause
        exit /b 1
    )
    :: Tim thu muc backup ben trong
    for /f "delims=" %%d in ('dir /B /A:D "!TEMP_EXTRACT!" 2^>nul') do (
        set "RESTORE_DIR=!TEMP_EXTRACT!\%%d"
    )
    echo [ OK ] Giai nen thanh cong
    call :LOG "OK: Giai nen vao !RESTORE_DIR!"
) else (
    set "RESTORE_DIR=!FULL_BACKUP_PATH!"
    echo [ OK ] Dung truc tiep thu muc backup
)

if not exist "!RESTORE_DIR!" (
    echo [FAIL] Khong tim thay thu muc backup de restore!
    call :LOG "LOI: Thu muc restore khong ton tai: !RESTORE_DIR!"
    pause
    exit /b 1
)

:: ============================================================
:: BUOC 4: Backup cau hinh hien tai truoc khi ghi de
:: ============================================================
echo.
echo [....] Backup cau hinh hien tai truoc khi ghi de...

set "PRE_RESTORE=backups\_pre_restore_%LOG_DATE%"
if exist "config" (
    xcopy "config" "!PRE_RESTORE!\config\" /E /I /Q >nul 2>&1
    echo [ OK ] Da backup cau hinh hien tai vao: !PRE_RESTORE!
    call :LOG "OK: Pre-restore backup: !PRE_RESTORE!"
)

:: ============================================================
:: BUOC 5: Khoi phuc config/
:: ============================================================
echo.
echo [....] Khoi phuc thu muc config/...

if exist "!RESTORE_DIR!\config" (
    if exist "config" rmdir /S /Q "config" >nul 2>&1
    xcopy "!RESTORE_DIR!\config" "config\" /E /I /Q >nul 2>&1
    echo [ OK ] Da khoi phuc config/
    call :LOG "OK: Khoi phuc config/"
) else (
    echo [WARN] Backup khong co thu muc config/
    call :LOG "CANH BAO: Khong co config/ trong backup"
)

:: ============================================================
:: BUOC 6: Khoi phuc data/
:: ============================================================
echo.
echo [....] Khoi phuc thu muc data/...

if exist "!RESTORE_DIR!\data" (
    if exist "data" rmdir /S /Q "data" >nul 2>&1
    xcopy "!RESTORE_DIR!\data" "data\" /E /I /Q >nul 2>&1
    echo [ OK ] Da khoi phuc data/
    call :LOG "OK: Khoi phuc data/"
) else (
    echo [INFO] Backup khong co thu muc data/ - bo qua
    call :LOG "INFO: Khong co data/ trong backup"
)

:: ============================================================
:: BUOC 7: Khoi phuc openclaw-system/
:: ============================================================
echo.
echo [....] Khoi phuc cau hinh he thong OpenClaw...

set "OC_CONFIG_DIR=%USERPROFILE%\.openclaw"

if exist "!RESTORE_DIR!\openclaw-system\openclaw.json" (
    if not exist "!OC_CONFIG_DIR!" mkdir "!OC_CONFIG_DIR!" >nul 2>&1
    copy "!RESTORE_DIR!\openclaw-system\openclaw.json" "!OC_CONFIG_DIR!\openclaw.json" >nul 2>&1
    echo [ OK ] Da khoi phuc openclaw.json
    call :LOG "OK: Khoi phuc openclaw.json"
)

if exist "!RESTORE_DIR!\openclaw-system\workspace" (
    if exist "!OC_CONFIG_DIR!\workspace" rmdir /S /Q "!OC_CONFIG_DIR!\workspace" >nul 2>&1
    xcopy "!RESTORE_DIR!\openclaw-system\workspace" "!OC_CONFIG_DIR!\workspace\" /E /I /Q >nul 2>&1
    echo [ OK ] Da khoi phuc workspace
    call :LOG "OK: Khoi phuc workspace"
)

if exist "!RESTORE_DIR!\openclaw-system\store" (
    if exist "!OC_CONFIG_DIR!\store" rmdir /S /Q "!OC_CONFIG_DIR!\store" >nul 2>&1
    xcopy "!RESTORE_DIR!\openclaw-system\store" "!OC_CONFIG_DIR!\store\" /E /I /Q >nul 2>&1
    echo [ OK ] Da khoi phuc store (xac thuc)
    call :LOG "OK: Khoi phuc store"
)

:: ============================================================
:: BUOC 8: Don dep thu muc tam
:: ============================================================
if "!SELECTED_BACKUP:~-7!"==".tar.gz" (
    if exist "!TEMP_EXTRACT!" rmdir /S /Q "!TEMP_EXTRACT!" >nul 2>&1
    call :LOG "Da xoa thu muc tam: !TEMP_EXTRACT!"
)

:: ============================================================
:: KET QUA
:: ============================================================
echo.
echo ============================================================
echo     KHOI PHUC HOAN THANH THANH CONG!
echo ============================================================
echo.
echo  Da khoi phuc tu: !SELECTED_BACKUP!
echo  Backup cau hinh cu tai: !PRE_RESTORE!
echo  Log: %LOGFILE%
echo.
echo  BUOC TIEP THEO:
echo  - Chay start.bat de khoi dong OpenClaw voi cau hinh da phuc hoi
echo.
call :LOG "=== KHOI PHUC HOAN THANH: !SELECTED_BACKUP! ==="
pause
exit /b 0

:LOG
echo %date% %time% - %~1 >> "%LOGFILE%" 2>nul
goto :eof

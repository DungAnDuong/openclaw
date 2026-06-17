@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title OpenClaw - Cai Dat Tu Dong

:: ============================================================
:: install.bat - Script cai dat tu dong OpenClaw
:: Phien ban: 2026.4.24
:: Tuong thich: Windows 10/11
:: ============================================================

echo.
echo ============================================================
echo     OPENCLAW - CAI DAT TU DONG
echo     Phien ban: 2026.4.24
echo ============================================================
echo.

:: --- Tao thu muc log ---
if not exist "logs" mkdir logs
set "LOGFILE=logs\install_%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"
set "LOGFILE=%LOGFILE: =0%"

call :LOG "=== BAT DAU CAI DAT ==="
call :LOG "Thoi gian: %date% %time%"

:: ============================================================
:: BUOC 1: Kiem tra Node.js
:: ============================================================
call :STEP "BUOC 1: Kiem tra Node.js..."

node --version >nul 2>&1
if errorlevel 1 (
    call :FAIL "Node.js chua duoc cai dat!"
    echo.
    echo  Node.js la yeu cau bat buoc de chay OpenClaw.
    echo  Phien ban yeu cau: Node.js 22.14+ (khuyen nghi: Node.js 24^)
    echo.
    echo  Tai tai: https://nodejs.org/en/download
    echo  Chon "LTS" hoac phien ban 24.x
    echo.
    echo  Sau khi cai xong, mo lai cua so lenh moi va chay lai install.bat
    echo.
    pause
    exit /b 1
)

for /f "tokens=1" %%v in ('node --version 2^>^&1') do set "NODE_VERSION=%%v"
call :LOG "Node.js phien ban: %NODE_VERSION%"
call :OK "Node.js: %NODE_VERSION%"

:: Kiem tra phien ban toi thieu (22)
for /f "tokens=1 delims=v." %%v in ("%NODE_VERSION%") do set "NODE_MAJOR=%%v"
for /f "tokens=2 delims=v." %%v in ("%NODE_VERSION%") do set "NODE_MAJOR=%%v"
if !NODE_MAJOR! LSS 22 (
    call :FAIL "Node.js phien ban qua cu: %NODE_VERSION%"
    echo  Can Node.js 22.14+ hoac moi hon. Hay cap nhat tai: https://nodejs.org
    pause
    exit /b 1
)

:: ============================================================
:: BUOC 2: Kiem tra npm
:: ============================================================
call :STEP "BUOC 2: Kiem tra npm..."

npm --version >nul 2>&1
if errorlevel 1 (
    call :FAIL "npm khong hoat dong! Cai lai Node.js."
    pause
    exit /b 1
)
for /f "tokens=1" %%v in ('npm --version 2^>^&1') do set "NPM_VERSION=%%v"
call :OK "npm: v%NPM_VERSION%"
call :LOG "npm phien ban: v%NPM_VERSION%"

:: ============================================================
:: BUOC 3: Kiem tra Git
:: ============================================================
call :STEP "BUOC 3: Kiem tra Git..."

git --version >nul 2>&1
if errorlevel 1 (
    call :WARN "Git chua duoc cai dat. Mot so tinh nang cap nhat co the khong hoat dong."
    echo  (Khong bat buoc, nhung khuyen nghi^)
    echo  Tai tai: https://git-scm.com/download/win
    call :LOG "CANH BAO: Git chua duoc cai dat"
) else (
    for /f "tokens=1,2,3" %%a in ('git --version 2^>^&1') do set "GIT_VERSION=%%c"
    call :OK "Git: v%GIT_VERSION%"
    call :LOG "Git phien ban: v%GIT_VERSION%"
)

:: ============================================================
:: BUOC 4: Kiem tra file cau hinh
:: ============================================================
call :STEP "BUOC 4: Kiem tra file cau hinh..."

:: Tao thu muc config neu chua co
if not exist "config" (
    mkdir config
    call :LOG "Da tao thu muc config"
)

:: Copy file mau neu chua ton tai
call :COPY_IF_NOT_EXIST "config\llm_config.json"
call :COPY_IF_NOT_EXIST "config\bot_config.json"
call :COPY_IF_NOT_EXIST "config\app_config.json"
call :COPY_IF_NOT_EXIST "config\paths.json"

:: Kiem tra API key
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$c = Get-Content 'config\llm_config.json' | ConvertFrom-Json; if ($c.api_key -eq 'YOUR_API_KEY_HERE' -or $c.api_key -eq '') { exit 1 } else { exit 0 }" >nul 2>&1
if errorlevel 1 (
    call :WARN "Ban chua dat API key trong config\llm_config.json"
    echo.
    echo  HAY LAM THEO CAC BUOC SAU:
    echo  1. Mo file: config\llm_config.json
    echo  2. Dien api_key that cua ban
    echo  3. Dat provider va model phu hop
    echo  4. Luu file va chay lai install.bat
    echo.
    call :LOG "CANH BAO: API key chua duoc cau hinh"
    pause
)

call :OK "File cau hinh da san sang"

:: ============================================================
:: BUOC 5: Cai dat OpenClaw
:: ============================================================
call :STEP "BUOC 5: Cai dat OpenClaw tu npm..."

echo  Dang cai openclaw@latest tu npm...
call :LOG "Bat dau cai openclaw tu npm"

npm install -g openclaw@latest 2>&1 | tee -a "%LOGFILE%"
if errorlevel 1 (
    call :FAIL "Cai dat OpenClaw that bai!"
    echo.
    echo  Co the do:
    echo  - Mat ket noi internet
    echo  - npm bị lỗi quyền (thu chay cmd voi quyen Administrator^)
    echo  - Registry npm bi chan
    echo.
    echo  Thu cach khac: npm install -g openclaw@latest --registry https://registry.npmjs.org
    echo.
    call :LOG "LOI: Cai dat openclaw that bai"
    pause
    exit /b 1
)

:: Xac nhan cai dat thanh cong
openclaw --version >nul 2>&1
if errorlevel 1 (
    call :FAIL "Cai dat xong nhung lenh openclaw khong hoat dong!"
    echo  Thu dong/mo lai cua so lenh (cmd/terminal^) va chay lai.
    call :LOG "LOI: Lenh openclaw khong nhan dien sau khi cai dat"
    pause
    exit /b 1
)

for /f "tokens=1" %%v in ('openclaw --version 2^>^&1') do set "OC_VERSION=%%v"
call :OK "OpenClaw da cai dat: v%OC_VERSION%"
call :LOG "OpenClaw phien ban: v%OC_VERSION%"

:: ============================================================
:: BUOC 6: Tao cac thu muc can thiet
:: ============================================================
call :STEP "BUOC 6: Tao cac thu muc he thong..."

for %%d in (logs data backups) do (
    if not exist "%%d" (
        mkdir "%%d"
        call :LOG "Da tao thu muc: %%d"
    )
)

:: Tao .gitkeep de git theo doi thu muc rong
if not exist "logs\.gitkeep" type nul > "logs\.gitkeep"
if not exist "data\.gitkeep" type nul > "data\.gitkeep"
if not exist "backups\.gitkeep" type nul > "backups\.gitkeep"

call :OK "Thu muc da tao xong"

:: ============================================================
:: BUOC 7: Ap dung cau hinh
:: ============================================================
call :STEP "BUOC 7: Ap dung cau hinh vao OpenClaw..."

powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\apply_openclaw_config.ps1" 2>&1 | tee -a "%LOGFILE%"
if errorlevel 1 (
    call :WARN "Co loi khi ap dung cau hinh. Kiem tra lai config\llm_config.json"
    call :LOG "CANH BAO: Loi ap dung cau hinh"
) else (
    call :OK "Cau hinh da duoc ap dung"
)

:: ============================================================
:: BUOC 8: Chay kiem tra he thong
:: ============================================================
call :STEP "BUOC 8: Kiem tra he thong..."

openclaw doctor 2>&1 | tee -a "%LOGFILE%"
if errorlevel 1 (
    call :WARN "openclaw doctor phat hien mot so van de. Xem log de biet them."
    call :LOG "CANH BAO: openclaw doctor bao loi"
) else (
    call :OK "Kiem tra he thong OK"
)

:: ============================================================
:: HOAN THANH
:: ============================================================
echo.
echo ============================================================
echo     CAI DAT HOAN THANH THANH CONG!
echo ============================================================
echo.
echo  BUOC TIEP THEO:
echo  1. Dam bao da dien API key trong: config\llm_config.json
echo  2. (Tuy chon) Cau hinh kenh chat trong: config\bot_config.json
echo  3. Chay: start.bat de khoi dong OpenClaw
echo  4. Mo trinh duyet tai: http://127.0.0.1:18789
echo.
echo  Log cai dat da luu tai: %LOGFILE%
echo.

call :LOG "=== CAI DAT HOAN THANH ==="
pause
exit /b 0

:: ============================================================
:: CAC HAM HO TRO
:: ============================================================

:STEP
echo.
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

:COPY_IF_NOT_EXIST
if not exist "%~1" (
    call :WARN "File %~1 khong ton tai - se duoc tao mau trong lan chay dau"
    call :LOG "CANH BAO: File mau khong co: %~1"
)
goto :eof

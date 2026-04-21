@echo off
REM ============================================================================
REM LOOM MONITORING SYSTEM - RUN FRONTEND + BACKEND IN ONE COMMAND
REM ============================================================================
REM For Windows Command Prompt (CMD)

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║  LOOM MONITORING SYSTEM - START FRONTEND + BACKEND            ║
echo ╚════════════════════════════════════════════════════════════════╝

REM Check prerequisites
echo.
echo [1/4] Checking prerequisites...

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed or not in PATH
    echo    Download from: https://nodejs.org/
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo ✓ Node.js: !NODE_VERSION!

where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ npm is not installed
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo ✓ npm: !NPM_VERSION!

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo    Download from: https://flutter.dev/
    pause
    exit /b 1
)
for /f "tokens=1-3" %%i in ('flutter --version') do (
    set FLUTTER_VERSION=%%i %%j %%k
    goto :got_flutter
)
:got_flutter
echo ✓ Flutter: !FLUTTER_VERSION!

REM Install backend dependencies
echo.
echo [2/4] Setting up backend dependencies...
if not exist "backend\node_modules" (
    echo Installing backend packages...
    cd backend
    call npm install
    cd ..
    echo ✓ Backend dependencies installed
) else (
    echo ✓ Backend dependencies already installed
)

REM Install frontend dependencies
echo.
echo [3/4] Setting up frontend dependencies...
if not exist "pubspec.lock" (
    echo Installing Flutter packages...
    call flutter pub get
    echo ✓ Frontend dependencies installed
) else (
    echo ✓ Frontend dependencies already installed
)

REM Check port 3000
echo.
echo [4/4] Checking port availability...
netstat -ano | findstr :3000 >nul
if !errorlevel! equ 0 (
    echo ⚠️  Port 3000 is already in use
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "!CONTINUE!"=="y" exit /b 1
)

REM Start services
echo.
echo [5/5] Starting services...

echo Starting backend server...
start "Backend - Loom Monitoring" cmd /k cd backend ^& npm run dev

timeout /t 3 /nobreak

echo Starting Flutter frontend...
start "Frontend - Loom Monitoring" cmd /k flutter run -d chrome

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║  ✓ BOTH SERVICES STARTED SUCCESSFULLY!                        ║
echo ╠════════════════════════════════════════════════════════════════╣
echo ║  Backend:  http://localhost:3000                              ║
echo ║  Frontend: Browser window will open                           ║
echo ║  WebSocket: ws://localhost:3000                              ║
echo ╠════════════════════════════════════════════════════════════════╣
echo ║  Close the windows to stop the services                       ║
echo ║  Check each window for logs and errors                        ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

pause

# ============================================================================
# LOOM MONITORING SYSTEM - RUN FRONTEND + BACKEND IN ONE COMMAND
# ============================================================================
# This script starts both the Node.js backend and Flutter frontend together

# Enable error handling
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  LOOM MONITORING SYSTEM - START FRONTEND AND BACKEND" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

# Function to check if command exists
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Check prerequisites
Write-Host "`n[1/4] Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
if (-not (Test-CommandExists "node")) {
    Write-Host "[ERROR] Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Download from: https://nodejs.org/" -ForegroundColor Gray
    exit 1
}
$nodeVersion = node --version
Write-Host "[OK] Node.js: $nodeVersion" -ForegroundColor Green

# Check npm
if (-not (Test-CommandExists "npm")) {
    Write-Host "[ERROR] npm is not installed or not in PATH" -ForegroundColor Red
    exit 1
}
$npmVersion = npm --version
Write-Host "[OK] npm: $npmVersion" -ForegroundColor Green

# Check Flutter
if (-not (Test-CommandExists "flutter")) {
    Write-Host "[ERROR] Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Download from: https://flutter.dev/" -ForegroundColor Gray
    exit 1
}
$flutterVersion = flutter --version | Select-Object -First 1
Write-Host "[OK] Flutter: $flutterVersion" -ForegroundColor Green

# Install backend dependencies
Write-Host "`n[2/4] Setting up backend dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "backend/node_modules")) {
    Write-Host "Installing backend packages..." -ForegroundColor Cyan
    Push-Location "backend"
    npm install
    Pop-Location
    Write-Host "[OK] Backend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Backend dependencies already installed" -ForegroundColor Green
}

# Install frontend dependencies
Write-Host "`n[3/4] Setting up frontend dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "pubspec.lock")) {
    Write-Host "Installing Flutter packages..." -ForegroundColor Cyan
    flutter pub get
    Write-Host "[OK] Frontend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Frontend dependencies already installed" -ForegroundColor Green
}

# Check if port 3000 is available
Write-Host "`n[4/4] Checking port availability..." -ForegroundColor Yellow
$portInUse = $null
try {
    $portInUse = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
}
catch {
    # Port is available
}

if ($portInUse) {
    Write-Host "[WARNING] Port 3000 is already in use" -ForegroundColor Yellow
    Write-Host "   Please close the application using port 3000, or modify backend/.env" -ForegroundColor Gray
    $response = Read-Host "   Continue anyway? (y/n)"
    if ($response -ne "y") {
        exit 1
    }
}

# Start backend
Write-Host "`n[5/5] Starting services..." -ForegroundColor Yellow
Write-Host "Starting backend server..." -ForegroundColor Cyan

Push-Location "backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev" -WindowStyle Normal
Pop-Location

Write-Host "[OK] Backend started in new window (port 3000)" -ForegroundColor Green

# Wait for backend to start
Write-Host "Waiting for backend to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Start frontend
Write-Host "Starting Flutter frontend..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "flutter run -d chrome" -WindowStyle Normal

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Green
Write-Host "  BOTH SERVICES STARTED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Green
Write-Host "  Backend:  http://localhost:3000" -ForegroundColor Green
Write-Host "  Frontend: http://localhost:5173 (or Chrome window)" -ForegroundColor Green
Write-Host "  WebSocket: ws://localhost:3000" -ForegroundColor Green
Write-Host "------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "  Close the terminal windows to stop the services" -ForegroundColor Yellow
Write-Host "  Check each window for logs and errors" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Green
Write-Host ""

# Keep the main window open
Read-Host "Press Enter to exit this window"

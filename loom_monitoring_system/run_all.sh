#!/bin/bash
# ============================================================================
# LOOM MONITORING SYSTEM - RUN FRONTEND + BACKEND IN ONE COMMAND
# ============================================================================
# For macOS and Linux users

set -e  # Exit on error

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  LOOM MONITORING SYSTEM - START FRONTEND + BACKEND            ║"
echo "╚════════════════════════════════════════════════════════════════╝"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo ""
echo "[1/4] Checking prerequisites..."

if ! command_exists "node"; then
    echo "❌ Node.js is not installed"
    echo "   Download from: https://nodejs.org/"
    exit 1
fi
NODE_VERSION=$(node --version)
echo "✓ Node.js: $NODE_VERSION"

if ! command_exists "npm"; then
    echo "❌ npm is not installed"
    exit 1
fi
NPM_VERSION=$(npm --version)
echo "✓ npm: $NPM_VERSION"

if ! command_exists "flutter"; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "   Download from: https://flutter.dev/"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -1)
echo "✓ Flutter: $FLUTTER_VERSION"

# Install backend dependencies
echo ""
echo "[2/4] Setting up backend dependencies..."
if [ ! -d "backend/node_modules" ]; then
    echo "Installing backend packages..."
    cd backend
    npm install
    cd ..
    echo "✓ Backend dependencies installed"
else
    echo "✓ Backend dependencies already installed"
fi

# Install frontend dependencies
echo ""
echo "[3/4] Setting up frontend dependencies..."
if [ ! -f "pubspec.lock" ]; then
    echo "Installing Flutter packages..."
    flutter pub get
    echo "✓ Frontend dependencies installed"
else
    echo "✓ Frontend dependencies already installed"
fi

# Check if port 3000 is available
echo ""
echo "[4/4] Checking port availability..."
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  Port 3000 is already in use"
    echo "   Please close the application using port 3000"
    read -p "   Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start services
echo ""
echo "[5/5] Starting services..."

# Start backend in background
echo "Starting backend server..."
cd backend
npm run dev &
BACKEND_PID=$!
cd ..

sleep 3

# Start frontend
echo "Starting Flutter frontend..."
flutter run -d chrome

# Cleanup on exit
trap "kill $BACKEND_PID" EXIT

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  ✓ SERVICES RUNNING                                           ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  Backend:  http://localhost:3000                              ║"
echo "║  Frontend: Browser window opened                              ║"
echo "║  WebSocket: ws://localhost:3000                              ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  Press Ctrl+C to stop all services                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Wait for user interrupt
wait

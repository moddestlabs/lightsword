#!/bin/bash

# Script to build and serve the LIGHTSWORD web app
# Usage: ./build.sh [--clean] [--port PORT]

set -e  # Exit on error

# Default values
PORT=8080
CLEAN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean)
      CLEAN=true
      shift
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--clean] [--port PORT]"
      exit 1
      ;;
  esac
done

# Kill any existing Python HTTP servers
echo "🛑 Checking for existing servers..."
if pgrep -f "python.*http.server" > /dev/null; then
  echo "   Stopping existing Python HTTP servers..."
  pkill -f "python.*http.server" || true
  sleep 1
fi

# Change to the bible_app directory
cd "$(dirname "$0")/bible_app"

echo "🔨 Building LIGHTSWORD web app..."

# Clean if requested
if [ "$CLEAN" = true ]; then
  echo "🧹 Cleaning previous build..."
  flutter clean
fi

# Build the web version
echo "📦 Building for web..."
flutter build web --release --no-wasm-dry-run

echo "🧰 Generating offline service worker..."
../scripts/generate_pwa_service_worker.sh build/web

# Check if build was successful
if [ ! -d "build/web" ]; then
  echo "❌ Build failed - build/web directory not found"
  exit 1
fi

# Change to the build output directory
cd build/web

echo "✅ Build complete!"
echo ""
echo "🌐 Starting fresh web server on http://localhost:$PORT"
echo "📖 Open the URL above in your browser to see the latest changes"
echo "🛑 Press Ctrl+C to stop the server"
echo ""

# Start the Python HTTP server
python3 -m http.server "$PORT"

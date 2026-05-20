#!/bin/bash
# Build release AAB with environment variables from .env file
# This script reads your local .env file and passes variables to flutter build as --dart-define flags

set -e  # Exit on error

# Change to project root directory
cd "$(dirname "$0")/.."

# Check if .env file exists
if [ ! -f ".env" ]; then
  echo "Error: .env file not found in project root"
  echo "Please create a .env file with your environment variables"
  exit 1
fi

# Load environment variables from .env file
echo "Loading environment variables from .env..."
export $(grep -v '^#' .env | xargs)

# Build the app bundle with environment variables
echo "Building release AAB with environment variables..."
flutter build appbundle --release \
  --dart-define=STRAPI_BASE_URL="${STRAPI_BASE_URL}" \
  --dart-define=STRAPI_API_TOKEN="${STRAPI_API_TOKEN}"

echo ""
echo "✅ Build complete!"
echo "📦 AAB location: build/app/outputs/bundle/release/app-release.aab"
echo "📏 Size: $(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)"

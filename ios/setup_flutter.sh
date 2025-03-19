#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "Setting up Flutter framework for iOS build..."

# Get the Flutter SDK path using which flutter
FLUTTER_BIN=$(which flutter)
FLUTTER_ROOT=${FLUTTER_BIN%/bin/flutter}
echo "Flutter SDK Path: $FLUTTER_ROOT"

# Create necessary directories
mkdir -p Flutter/Debug
mkdir -p Flutter/Release
mkdir -p Flutter/Profile

# Ensure Flutter engine cache is up to date
echo "Ensuring Flutter framework is downloaded..."
flutter precache --ios --force

# Find Flutter.framework in possible locations
FLUTTER_LOCATIONS=(
  "$FLUTTER_ROOT/bin/cache/artifacts/engine/ios/Flutter.framework"
  "$FLUTTER_ROOT/bin/cache/artifacts/engine/ios-release/Flutter.framework" 
  "$FLUTTER_ROOT/bin/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework"
  "$FLUTTER_ROOT/bin/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64/Flutter.framework"
)

FOUND_FRAMEWORK=false
for LOCATION in "${FLUTTER_LOCATIONS[@]}"; do
  if [ -d "$LOCATION" ]; then
    echo "Found Flutter.framework at $LOCATION"
    echo "Copying to Debug and Release directories..."
    cp -R "$LOCATION" Flutter/Debug/
    cp -R "$LOCATION" Flutter/Release/
    FOUND_FRAMEWORK=true
    break
  fi
done

if [ "$FOUND_FRAMEWORK" = false ]; then
  # Try building frameworks directly
  echo "Could not find Flutter.framework, building directly..."
  cd ..
  flutter build ios-framework --output=ios/Flutter --no-profile
  cd ios
  
  if [ ! -d "Flutter/Debug/Flutter.framework" ]; then
    echo "Error: Failed to generate Flutter.framework"
    exit 1
  fi
  
  echo "Flutter framework created successfully."
else
  # Generate the App.framework
  echo "Building App.framework..."
  cd ..
  flutter build ios-framework --output=ios/Flutter --no-profile --no-release
  cd ios
fi

echo "Running pod install..."
pod install

echo "Flutter framework setup completed successfully!" 
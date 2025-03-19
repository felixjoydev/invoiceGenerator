#!/bin/bash

echo "Cleaning iOS project..."

# Remove build artifacts
rm -rf build
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock
rm -f .flutter-plugins-dependencies

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*felix.invoicegenerator*

# Ensure Flutter directory exists
mkdir -p Flutter/Debug
mkdir -p Flutter/Release

echo "Setting up Flutter framework..."
FLUTTER_ROOT=$(which flutter)
FLUTTER_ROOT=${FLUTTER_ROOT%/bin/flutter}
echo "Flutter root: $FLUTTER_ROOT"

# Force Flutter to download frameworks
cd ..
echo "Ensuring iOS frameworks are available..."
flutter precache --ios --force
cd ios

# Get the Flutter.framework from the Flutter SDK
FLUTTER_ENGINE="$FLUTTER_ROOT/bin/cache/artifacts/engine"

# Check all possible locations for Flutter.framework
POSSIBLE_LOCATIONS=(
  "$FLUTTER_ENGINE/ios-release/Flutter.framework"
  "$FLUTTER_ENGINE/ios/Flutter.framework"
  "$FLUTTER_ENGINE/ios/Flutter.xcframework/ios-arm64/Flutter.framework"
  "$FLUTTER_ENGINE/ios/Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework"
)

FOUND_FRAMEWORK=false
for LOCATION in "${POSSIBLE_LOCATIONS[@]}"; do
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
  echo "Error: Could not find Flutter.framework in any standard location"
  echo "Trying to build it directly..."
  
  # Try to build Flutter framework directly
  cd ..
  echo "Building iOS frameworks..."
  flutter build ios-framework --no-profile --output=ios/Flutter
  
  if [ ! -d "ios/Flutter/Debug/Flutter.framework" ]; then
    echo "Error: Failed to generate Flutter.framework"
    exit 1
  fi
  
  cd ios
fi

# Generate Flutter config
cd ..
echo "Running flutter clean..."
flutter clean
echo "Running flutter pub get..."
flutter pub get

cd ios
echo "Running pod install..."
pod install

echo "iOS project cleaned and set up successfully!" 
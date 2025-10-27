#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Repeat Cycle ---"

# 1. Source the environment file to bring in the local toolchain
echo "Activating local toolchain..."
if [ -f "local/env" ]; then
    source "local/env"
else
    echo "Error: local/env not found. Please run wash.bash first."
    exit 1
fi

# 2. Build the Android application
echo "Building the Android application (debug)..."
# On Windows runners, Gradle/AGP may use the Ninja bundled with the Android SDK's CMake (often older).
# Ensure the SDK CMake uses the system Ninja (installed/pinned to >= 1.12 via workflow) to avoid MAX_PATH issues.
OS="`uname`"
if [[ "$OS" == MINGW64_NT-10.0* || "$OS" == MSYS_NT-10.0* ]]; then
    echo "Aligning Android SDK CMake's ninja.exe with system ninja..."
    if command -v ninja >/dev/null 2>&1; then
        NINJA_BIN="$(command -v ninja)"
        echo "System ninja: $NINJA_BIN ($(ninja --version 2>/dev/null))"
        shopt -s nullglob
        UPDATED_ANY=false
        for f in "$ANDROID_SDK_ROOT"/cmake/*/bin/ninja.exe; do
            echo "Replacing: $f"
            cp -f "$NINJA_BIN" "$f"
            echo " -> now $f reports: $("$f" --version 2>/dev/null || echo unknown)"
            UPDATED_ANY=true
        done
        shopt -u nullglob
        if [ "$UPDATED_ANY" = false ]; then
            echo "No SDK CMake ninja.exe found under $ANDROID_SDK_ROOT/cmake/*/bin — continuing."
        fi
    else
        echo "Warning: 'ninja' not found in PATH; cannot align SDK CMake ninja."
    fi
fi
(cd workspace/AwesomeProject/android && ./gradlew assembleDebug)

# 3. Copy the APK to the dist folder
echo "Copying APK to dist folder..."
mkdir -p dist
APK_PATH="workspace/AwesomeProject/android/app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    cp "$APK_PATH" "dist/AwesomeProject-debug.apk"
else
    echo "Error: Build failed, APK not found at $APK_PATH"
    exit 1
fi

echo "--- Repeat Cycle Complete ---"
echo "Success! Your application has been built."
echo "You can install it on a connected device with:"
echo "adb install -r dist/AwesomeProject-debug.apk"

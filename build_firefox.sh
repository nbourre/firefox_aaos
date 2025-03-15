#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error and exit immediately
set -o pipefail  # Prevents errors in a pipeline from being masked

# Ubuntu 24.04.01
# -------------
# Initial Dev Setup - Only needed to be done once 
# Refer to: https://firefox-source-docs.mozilla.org/setup/linux_build.html
# Follow step 1.1 (Install dependencies)
# Skip step 1.2 (Will use GIT)
# Follow step 2 (Get source code)
# Select "GeckoView/Firefox for Android Artifact Mode"
# Skip remaining steps 
# Ensure "patch.patch" is edited to replace "com.CHANGEME" with a unique ID.
# Install the latest Android Studio

echo "Starting Firefox build script..."

SRC_HOME="$HOME/mozilla-unified"
PATCH="$HOME/firefox_aaos/updated_patch.patch"
FENIX="$SRC_HOME/mobile/android/fenix"
GRADLE="$FENIX/app/build.gradle"
VERSION_FILE="$SRC_HOME/mobile/android/version.txt"
VERSION_DATE=$(date +'%Y%m%d%M')
VERSION='147.002'

# Check required files and directories
if [ ! -d "$SRC_HOME" ]; then
  echo "Error: Source directory $SRC_HOME does not exist. Please ensure the source code is cloned."
  exit 1
fi

if [ ! -f "$PATCH" ]; then
  echo "Error: Patch file $PATCH not found. Ensure it exists and has been modified correctly."
  exit 1
fi

echo "Navigating to source directory: $SRC_HOME"
cd "$SRC_HOME"

echo "Resetting source to avoid conflicts..."
git reset --hard

echo "Pulling the latest changes from the repository..."
git pull || { echo "Error: Failed to pull latest changes."; exit 1; }

echo "Applying patch: $PATCH"
git apply "$PATCH" || { echo "Error: Failed to apply patch. Ensure it's correctly formatted."; exit 1; }

# Update version
if [ -f "$GRADLE" ]; then
  echo "Updating version in Gradle file..."
  sed -i "s/\CHANGEME\b/${VERSION_DATE}/g" "$GRADLE"
else
  echo "Error: Gradle file $GRADLE not found. Cannot update version."
  exit 1
fi

echo "Writing version number to $VERSION_FILE"
echo "$VERSION" > "$VERSION_FILE"

# Build core Mozilla
echo "Running Mozilla bootstrap process..."
./mach --no-interactive bootstrap --application-choice="GeckoView/Firefox for Android Artifact Mode" || { echo "Error: Bootstrap failed."; exit 1; }

echo "Running clobber to remove previous build artifacts..."
./mach clobber || { echo "Error: Clobber failed."; exit 1; }

# Update mozconfig
echo "Configuring mozconfig file..."
cat > "$SRC_HOME/mozconfig" <<EOL
ac_add_options --enable-project=mobile/android
ac_add_options --enable-release
ac_add_options --enable-artifact-builds
ac_add_options --target=aarch64
ac_add_options --disable-tests
ac_add_options --disable-debug
ac_add_options --disable-updater
ac_add_options --disable-crashreporter
# Write build artifacts to:
mk_add_options MOZ_OBJDIR=./objdir-frontend
unset MOZ_TELEMETRY_REPORTING
EOL

echo "Starting build process..."
./mach build || { echo "Error: Build failed."; exit 1; }

echo "---------------CONFIGURATION COMPLETE--------------"
echo "Check for any errors above as this script includes error handling."
echo

echo "--------- Publish to Play Store -------------"
echo "To publish to the Play Store, the .aab needs to be created and signed."
echo "Android Studio is the simplest option to do this. Ensure Android Studio is installed."
echo

echo "Instructions:"
echo "1. Open Android Studio -> Open Folder -> ${SRC_HOME}/mobile/android/fenix"
echo "2. Ensure there are no Gradle errors (some warnings/errors are normal and can be Googled)."
echo "3. Build -> Generate Signed Bundle -> Select FenixRelease (or Nightly if issues occur)."

echo "Build process complete!"

# TODO
# Get the right version of Java
#   sudo apt install openjdk-17-jdk
#   sudo update-alternatives --config java
# Check for Android SDK
#   if not there `sudo apt install android-sdk`
# Add the variables to the path
#   export ANDROID_HOME=/usr/lib/android-sdk
#   export ANDROID_SDK_ROOT=/usr/lib/android-sdk
#   export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH
#   echo 'export ANDROID_HOME=/usr/lib/android-sdk' >> ~/.bashrc
#   echo 'export ANDROID_SDK_ROOT=/usr/lib/android-sdk' >> ~/.bashrc
#   echo 'export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH' >> ~/.bashrc
#   source ~/.bashrc
# Create local.properties file in the root of the project
#   sdk.dir=/usr/lib/android-sdk
# ./gradlew clean
# Try to build with Gradle `./gradlew bundleRelease`
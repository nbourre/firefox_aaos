#!/bin/sh

# Ubuntu 24.04.01
# -------------
# Initial Dev Setup - Only needed to be done once 
# https://firefox-source-docs.mozilla.org/setup/linux_build.html
# Do step 1.1
# Skip 1.2 (will use GIT)
# Do step 2
# Leave everything as default except select "GeckoView/Firefox for Android Artifact Mode"
# Skip remaining steps 
# edit the patch.patch file and replace "com.CHANGEME" with a unique ID. Don't change the other version CHANGEME
# Install latest android studio

SRC_HOME="$HOME/Downloads/mozilla-unified"
PATCH="$HOME/Downloads/firefox_aaos/patch.patch"
FENIX="$SRC_HOME/mobile/android/fenix"
GRADLE="$FENIX/app/build.gradle"
VERSION_FILE="$SRC_HOME/mobile/android/version.txt"
VERSION_DATE=$(date +'%Y%-m%d%M')
VERSION='147.002'

# cd in source directory
cd $SRC_HOME
# update source
git reset --hard
git pull

# apply patch
# ENSURE YOU CHANGED THE APPLICATION ID IN THE .patch FILE
git apply $PATCH

# update version
sed -i "s/\CHANGEME\b/${VERSION_DATE}/g" ${GRADLE}
echo ${VERSION} > $VERSION_FILE

# Build core mozilla
./mach --no-interactive bootstrap --application-choice="GeckoView/Firefox for Android Artifact Mode"
./mach clobber

# Update mozconfig
cat >${SRC_HOME}/mozconfig <<EOL
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

./mach build

echo ---------------CONFIGURATION COMPLETE--------------
echo Check for any errors above as this script does no error checking
echo
echo ---------Publish to Play Store-------------
echo To publish to play store, the .aab needs to be created and signed. 
echo Android studio is is the simpliest option to do this. Ensure android studio is installed. 
echo
echo "Open Android Studio" -> "Open Folder" -> ${SRC_HOME}/mobile/android/fenix
echo "There should be no errors during the loading of the gradle. If errors show up, these are normal Android/Firefox errors that can be solved via google, and have nothing to do with the customizations here."
echo "Build -> Generate app signed bundle -> FenixRelease"


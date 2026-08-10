#!/bin/bash
# Exit on any error
set -e

# Configure git safety checks for serverless environment
git config --global --add safe.directory '*'

# Setup Flutter SDK
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="3.44.9"

echo "=== System Pre-requisites Check ==="
echo "Operating System: $(uname -a)"
echo "Current Directory: $(pwd)"

echo "=== Downloading Flutter SDK ($FLUTTER_VERSION) ==="
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

echo "=== Extracting Flutter SDK ==="
tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Configuring Flutter ==="
flutter config --no-analytics
flutter config --enable-web

echo "=== Verifying Flutter Toolchain ==="
flutter doctor

echo "=== Building Flutter Web Application ==="
flutter build web --release

echo "=== Clean Up ==="
rm -f flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

echo "=== Build Completed Successfully ==="

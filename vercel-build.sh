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

echo "=== Transitioning to Web Project Folder ==="
cd web_version

echo "=== Generating env.json dynamically for compilation ==="
cat <<EOF > env.json
{
  "SUPABASE_URL": "https://ckyopijftlasebanhhqm.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_pztyR-WMEHV-T7k2MUgrlg_0KkpC75H",
  "OPENAI_API_KEY": "${OPENAI_API_KEY:-your-openai-api-key-here}",
  "GEMINI_API_KEY": "${GEMINI_API_KEY:-your-gemini-api-key-here}",
  "ANTHROPIC_API_KEY": "${ANTHROPIC_API_KEY:-your-anthropic-api-key-here}",
  "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY:-your-perplexity-api-key-here}",
  "GOOGLE_WEB_CLIENT_ID": "${GOOGLE_WEB_CLIENT_ID:-1053905240243-0olgtcdiieuu55s4qnm7792gg8fkndjr.apps.googleusercontent.com}",
  "RAZORPAY_KEY_ID": "${RAZORPAY_KEY_ID:-rzp_live_TUJq20NaHDggTH}",
  "RAZORPAY_WEBHOOK_SECRET": "${RAZORPAY_WEBHOOK_SECRET:-%%RAZORPAY_WEBHOOK_SECRET%%}",
  "TWILIO_ACCOUNT_SID": "${TWILIO_ACCOUNT_SID:-%%TWILIO_ACCOUNT_SID%%}",
  "TWILIO_AUTH_TOKEN": "${TWILIO_AUTH_TOKEN:-%%TWILIO_AUTH_TOKEN%%}",
  "TWILIO_PHONE_NUMBER": "${TWILIO_PHONE_NUMBER:-%%TWILIO_PHONE_NUMBER%%}",
  "RAZORPAY_KEY_SECRET": "${RAZORPAY_KEY_SECRET:-rslyTl3b3uWC8sBGCPVY0Rx9}",
  "ADMIN_EMAIL": "${ADMIN_EMAIL:-}",
  "TESTING_MODE": "${TESTING_MODE:-false}"
}
EOF

echo "=== Installing Dependencies ==="
flutter pub get

echo "=== Building Flutter Web Application ==="
flutter build web --release --dart-define-from-file=env.json --no-tree-shake-icons

echo "=== Clean Up ==="
cd ..
rm -f flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

echo "=== Build Completed Successfully ==="

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

echo "=== Generating env.json dynamically for compilation ==="
cat <<EOF > env.json
{
  "SUPABASE_URL": "${SUPABASE_URL:-http://localhost:3000}",
  "SUPABASE_ANON_KEY": "${SUPABASE_ANON_KEY:-mock-anon-key-localconnect-mongodb}",
  "OPENAI_API_KEY": "${OPENAI_API_KEY:-your-openai-api-key-here}",
  "GEMINI_API_KEY": "${GEMINI_API_KEY:-your-gemini-api-key-here}",
  "ANTHROPIC_API_KEY": "${ANTHROPIC_API_KEY:-your-anthropic-api-key-here}",
  "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY:-your-perplexity-api-key-here}",
  "GOOGLE_WEB_CLIENT_ID": "${GOOGLE_WEB_CLIENT_ID:-78703580798-ga1vsmbjl90te533l9imt84ub1l12p4d.apps.googleusercontent.com}",
  "RAZORPAY_KEY_ID": "${RAZORPAY_KEY_ID:-rzp_test_T8aOQO5SeDkUao}",
  "RAZORPAY_WEBHOOK_SECRET": "${RAZORPAY_WEBHOOK_SECRET:-%%RAZORPAY_WEBHOOK_SECRET%%}",
  "TWILIO_ACCOUNT_SID": "${TWILIO_ACCOUNT_SID:-%%TWILIO_ACCOUNT_SID%%}",
  "TWILIO_AUTH_TOKEN": "${TWILIO_AUTH_TOKEN:-%%TWILIO_AUTH_TOKEN%%}",
  "TWILIO_PHONE_NUMBER": "${TWILIO_PHONE_NUMBER:-%%TWILIO_PHONE_NUMBER%%}",
  "RAZORPAY_KEY_SECRET": "${RAZORPAY_KEY_SECRET:-%%RAZORPAY_KEY_SECRET%%}",
  "ADMIN_EMAIL": "${ADMIN_EMAIL:-}",
  "TESTING_MODE": "${TESTING_MODE:-false}"
}
EOF

echo "=== Configuring Web Platform in Project ==="
flutter create --platforms=web .

echo "=== Building Flutter Web Application ==="
flutter build web --release --dart-define-from-file=env.json

echo "=== Clean Up ==="
rm -f flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

echo "=== Build Completed Successfully ==="

#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export FLUTTER_SUPPRESS_ANALYTICS=true
flutter --suppress-analytics pub get
flutter --suppress-analytics build ipa --release
printf '\nBuild finished. Archive: build/ios/archive/Runner.xcarchive\nIPA output: build/ios/ipa/\n'

#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
export FLUTTER_SUPPRESS_ANALYTICS=true
flutter --suppress-analytics pub get
flutter --suppress-analytics build ipa --release
ipas=("$PWD"/build/ios/ipa/*.ipa(N))
(( ${#ipas} > 0 )) || { printf 'Archive may have succeeded, but no IPA was produced. See export errors above.\n' >&2; exit 1; }
printf '\nIPA created: %s\n' "${ipas[@]}"

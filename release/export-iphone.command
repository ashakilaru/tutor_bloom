#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
# Apple rsync starts a helper through PATH. Keep both processes on Apple's version.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
archive="$PWD/build/ios/archive/Runner.xcarchive"
[[ -d "$archive" ]] || { printf 'No archive found. Run build-iphone.command first.\n' >&2; exit 1; }
bloom_export_options=$(mktemp /private/tmp/tutor-bloom-export.XXXXXX)
trap 'rm -f "$bloom_export_options"' EXIT
cat > "$bloom_export_options" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>app-store-connect</string>
<key>signingStyle</key><string>automatic</string>
<key>teamID</key><string>LSWPD677NA</string>
<key>destination</key><string>export</string>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$archive" -exportOptionsPlist "$bloom_export_options" -exportPath "$PWD/build/ios/ipa" -allowProvisioningUpdates
ipas=("$PWD"/build/ios/ipa/*.ipa(N))
(( ${#ipas} > 0 )) || { printf 'Export did not produce an IPA.\n' >&2; exit 1; }
printf '\nIPA created: %s\n' "${ipas[@]}"

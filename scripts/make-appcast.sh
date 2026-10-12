#!/bin/bash
# Writes a single-item Sparkle appcast for a release archive.
#
#   SPARKLE_PRIVATE_KEY=... scripts/make-appcast.sh <sign_update> <version> <build> <archive.zip> <download-url> <out.xml>
#
# Sparkle only needs the newest item, and the feed URL always resolves to the latest release's copy.
set -euo pipefail

sign_update="$1" version="$2" build="$3" archive="$4" url="$5" output="$6"

signature="$(printf '%s' "$SPARKLE_PRIVATE_KEY" | "$sign_update" --ed-key-file - "$archive")"
published="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"

cat > "$output" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Focus Up</title>
    <item>
      <title>Version ${version}</title>
      <pubDate>${published}</pubDate>
      <sparkle:version>${build}</sparkle:version>
      <sparkle:shortVersionString>${version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>27.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/bevanjkay/focus-up/releases/tag/v${version}</sparkle:releaseNotesLink>
      <enclosure url="${url}" type="application/octet-stream" ${signature} />
    </item>
  </channel>
</rss>
XML
echo "Wrote ${output}"

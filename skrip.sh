#!/bin/bash

URL_BLOG="https://styleanecdotes.blogspot.com/2024/11/tv9.html"
REFERER="https://www.tvmy.online/"

echo "==> Memuat turun halaman blog..."
HTML_DATA=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -e "$REFERER" "$URL_BLOG")

# 1. Ekstrak pautan MPD
MPD_LINK=$(echo "$HTML_DATA" | grep -oE "https://[^'\"]+\.mpd" | head -n 1)

# 2. Ekstrak baris ClearKey pertama (menyokong " atau ')
KEY_LINE=$(echo "$HTML_DATA" | grep -oE "['\"][a-f0-9]{32}['\"]\s*:\s*['\"][a-f0-9]{32}['\"]" | head -n 1)

if [ -z "$MPD_LINK" ] || [ -z "$KEY_LINE" ]; then
    echo "❌ ERROR: Gagal menjumpai MPD atau ClearKey dalam HTML!"
    exit 1
fi

# 3. Bersihkan pembuka kata supaya tinggal hex sahaja
# Contoh pembersihan: '60dc08aa...' : '30d5b579...' -> 60dc08aa... dan 30d5b579...
KID=$(echo "$KEY_LINE" | cut -d':' -f1 | sed "s/['\"]//g" | xargs)
KEY=$(echo "$KEY_LINE" | cut -d':' -f2 | sed "s/['\"]//g" | xargs)

echo "✅ Data Berjaya Diekstrak!"
echo "MPD URL : $MPD_LINK"
echo "DRM KID : $KID"
echo "DRM KEY : $KEY"

# 4. Bina fail index.mpd yang lengkap dengan BaseURL & ClearKey
cat <<EOF > index.mpd
<?xml version="1.0" encoding="utf-8"?>
<MPD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xmlns="urn:mpeg:dash:schema:mpd:2011"
     xmlns:clearkey="http://dashif.org/guidelines/clearKey"
     xsi:schemaLocation="urn:mpeg:dash:schema:mpd:2011 DASH-MPD.xsd"
     profiles="urn:mpeg:dash:profile:isoff-live:2011"
     type="static">
  
  <BaseURL>$MPD_LINK</BaseURL>

  <Period id="1">
    <AdaptationSet Remarks="Suntikan ClearKey DRM">
      <ContentProtection schemeIdUri="urn:uuid:1077efec-c0b2-4d02-ace3-3c1e52e2fb4b">
        <clearkey:Laurl>{"keys":[{"kty":"oct","kid":"$KID","k":"$KEY"}]}</clearkey:Laurl>
      </ContentProtection>
    </AdaptationSet>
  </Period>
</MPD>
EOF

echo "==> Fail index.mpd berjaya dikemas kini!"

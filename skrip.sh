#!/bin/bash

# 1. Curl blog dengan Referer yang sah
URL_BLOG="https://styleanecdotes.blogspot.com/2024/11/tv9.html"
REFERER="https://www.tvmy.online/"

echo "Mengekstrak data dari blog..."
HTML_DATA=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -e "$REFERER" "$URL_BLOG")

# 2. Cari link MPD asal
MPD_LINK=$(echo "$HTML_DATA" | grep -oE "https://[^'\"]+\.mpd" | head -n 1)

# 3. Cari ClearKey
KEY_DATA=$(echo "$HTML_DATA" | grep -oE '"[a-f0-9]{32}":\s*"[a-f0-9]{32}"' | head -n 1)

if [ -z "$MPD_LINK" ] || [ -z "$KEY_DATA" ]; then
    echo "Gagal menjumpai MPD atau Key. Skrip dihentikan."
    exit 1
fi

# Asingkan Hex ID dan Hex Key
# Contoh asal: "60dc08aae52f4c0b806a8e43f24a12c8": "30d5b579966d822b215ec51a91d8a271"
KID=$(echo "$KEY_DATA" | cut -d':' -f1 | sed 's/[[:space:]]"//g' | sed 's/"//g')
KEY=$(echo "$KEY_DATA" | cut -d':' -f2 | sed 's/[[:space:]]"//g' | sed 's/"//g')

echo "MPD Original: $MPD_LINK"
echo "KID Jumpa: $KID"
echo "KEY Jumpa: $KEY"

# 4. Bina fail index.mpd (Format XML DASH dengan ClearKey terbina dalam)
cat <<EOF > index.mpd
<?xml version="1.0" encoding="utf-8"?>
<MPD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xmlns="urn:mpeg:dash:schema:mpd:2011"
     xmlns:xlink="http://www.w3.org/1999/xlink"
     xsi:schemaLocation="urn:mpeg:dash:schema:mpd:2011 DASH-MPD.xsd"
     profiles="urn:mpeg:dash:profile:isoff-live:2011"
     type="static">
  
  <Period id="1">
    <AdaptationSet Remarks="Suntikan ClearKey DRM">
      <ContentProtection schemeIdUri="urn:uuid:1077efec-c0b2-4d02-ace3-3c1e52e2fb4b">
        <clearkey:Laurl xmlns:clearkey="http://dashif.org/guidelines/clearKey">{"keys":[{"kty":"oct","kid":"$KID","k":"$KEY"}]}</clearkey:Laurl>
      </ContentProtection>
      
      <Subset contains="0" id="1"/>
    </AdaptationSet>
  </Period>
</MPD>
EOF

echo "Fail index.mpd berjaya dikemas kini!"

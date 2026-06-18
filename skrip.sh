#!/bin/bash

# 1. Curl blog dengan Referer yang sah supaya tidak kena sekat/Not Found
URL_BLOG="https://styleanecdotes.blogspot.com/2024/11/tv9.html"
REFERER="https://www.tvmy.online/"

echo "Mengekstrak data dari blog..."
HTML_DATA=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -e "$REFERER" "$URL_BLOG")

# 2. Cari link MPD menggunakan grep/sed
MPD_LINK=$(echo "$HTML_DATA" | grep -oE "https://[^'\"]+\.mpd" | head -n 1)

# 3. Cari ClearKey (Kunci DRM)
# Mencari string berbentuk "hex_id": "hex_key"
KEY_DATA=$(echo "$HTML_DATA" | grep -oE '"[a-f0-9]{32}":\s*"[a-f0-9]{32}"' | head -n 1)

if [ -z "$MPD_LINK" ] || [ -z "$KEY_DATA" ]; then
    echo "Gagal menjumpai MPD atau Key. Skrip dihentikan."
    exit 1
fi

# Bersihkan format key menjadi ID:KEY (buang pembuka kata dan titik bertindih rapat)
CLEAN_KEY=$(echo "$KEY_DATA" | sed 's/"//g' | sed 's/\s*:\s*/:/g')

echo "MPD Jumpa: $MPD_LINK"
echo "Key Jumpa: $CLEAN_KEY"

# 4. Bina fail index.m3u8 dengan format yang anda mahukan
cat <<EOF > index.m3u8
#EXTM3U
#EXTINF:-1, TV3 Live
#KODIP-DRM-TYPE="clearkey"
#KODIP-DRM-KEY="$CLEAN_KEY"
#EXT-X-STREAM-INF:BANDWIDTH=390000,CODECS="avc1.4d0015,mp4a.40.2",RESOLUTION=426x240
$MPD_LINK
EOF

echo "Fail index.m3u8 berjaya dikemas kini!"


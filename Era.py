import time
import json
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

# Setup Headless Chrome untuk pelayan Ubuntu GitHub
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.set_capability("goog:loggingPrefs", {"performance": "ALL"})

driver = webdriver.Chrome(options=chrome_options)
driver.get("https://audio1.syok.my/era")
time.sleep(10) # Ditambah masa sikit bagi pelayan Ubuntu sempat muat turun JavaScript

logs = driver.get_log("performance")
m3u8_link = None

for entry in logs:
    log_data = json.loads(entry["message"])["message"]
    if "Network.requestWillBeSent" in log_data.get("method", ""):
        params = log_data.get("params", {})
        
        # PERBAIKAN UTAMA: Periksa keselamatan objek request sebelum ambil URL
        if "request" in params:
            url = params["request"].get("url", "")
            if "revma" in url and "m3u8" in url:
                m3u8_link = url
                break

driver.quit()

if m3u8_link:
    print(f"[+] Berjaya jumpa link Revma yang segar: {m3u8_link}")
    
    # Laluan folder baru yang anda tetapkan di luar
    folder_path = "pass=liveradio/user=alamradio/brands=astro/search=era/number=856"
    
    # Cipta susunan folder secara automatik jika belum wujud
    os.makedirs(folder_path, exist_ok=True)
    
    # Bina kandungan fail index.m3u8
    m3u8_content = f"""#EXTM3U
#EXTINF:-1 tvg-id="Era_FM" tvg-name="ERA FM" tvg-logo="https://raw.githubusercontent.com/ziqryadam86-collab/Live/main/logos/era.png" group-title="RADIO",ERA FM (Auto Update)
{m3u8_link}
"""
    
    # Tulis fail terus ke dalam sasaran laluan baharu
    with open(f"{folder_path}/index.m3u8", "w") as f:
        f.write(m3u8_content)
    print(f"[+] Sukses! Fail index.m3u8 dikemas kini di laluan baharu.")
else:
    print("[-] Gagal menangkap link m3u8 Revma. Log tamat.")
    exit(1)

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
time.sleep(7) # Bagi masa pelayan GitHub memuatkan halaman JavaScript Syok

logs = driver.get_log("performance")
m3u8_link = None

for entry in logs:
    log = json.loads(entry["message"])["message"]
    if "Network.requestWillBeSent" in log["method"]:
        url = log["params"]["request"]["url"]
        if "revma" in url and "m3u8" in url:
            m3u8_link = url
            break

driver.quit()

if m3u8_link:
    print(f"[+] Berjaya jumpa link Revma: {m3u8_link}")
    
    # Laluan FOLDER BAHARU yang Maharaja Adam minta
    folder_path = "pass=liveradio/user=alamradio/brands=astro/search=era/number=856"
    
    # Cipta folder secara automatik kalau belum wujud dalam repo
    os.makedirs(folder_path, exist_ok=True)
    
    # Kandungan fail index.m3u8 yang akan dimasukkan
    m3u8_content = f"""#EXTM3U
#EXTINF:-1 tvg-id="Era_FM" tvg-name="ERA FM" tvg-logo="https://raw.githubusercontent.com/ziqryadam86-collab/Live/main/logos/era.png" group-title="RADIO",ERA FM (Auto Update)
{m3u8_link}
"""
    
    # Tulis fail terus ke laluan baharu tersebut
    with open(f"{folder_path}/index.m3u8", "w") as f:
        f.write(m3u8_content)
    print(f"[+] Fail index.m3u8 berjaya dikemas kini di laluan: {folder_path}/index.m3u8")
else:
    print("[-] Gagal tangkap link m3u8. Proses dihentikan.")
    exit(1)


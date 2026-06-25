#!/usr/bin/env bash
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
echo "=== doomworld idgames API with browser UA ==="
curl -s -A "$UA" "https://www.doomworld.com/idgames/api/api.php?out=json&action=search&type=title&query=eviternity" | head -c 400
echo; echo "=== alt: doomworld /idgames json via api action=get ==="
curl -s -A "$UA" "https://www.doomworld.com/idgames/api/api.php?out=json&action=about" | head -c 300

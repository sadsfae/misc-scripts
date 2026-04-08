#!/bin/bash

# ==========================================
# 1. Configuration & Setup
# ==========================================
WIKI_DIR="/var/www/html/p99wiki"
DOMAIN="p99.funcamp.net"
YACY_DOMAIN="eq.funcamp.net"

echo "Initializing P99 Wiki Mirror Sync..."

# Force the script to move into the target directory before doing anything else
cd "$WIKI_DIR" || {
  echo "Fatal: Directory $WIKI_DIR not found!"
  exit 1
}

# ==========================================
# 2. Asset Collapsing
# ==========================================
echo "Step 1: Collapsing dynamic CSS and JS assets..."
wget -qO- "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=mediawiki.legacy.commonPrint%2Cshared%7Cskins.monobook&only=styles&skin=monobook&*" "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=site&only=styles&skin=monobook&*" >"p99-offline.css"

wget -qO- "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=startup&only=scripts&skin=monobook&*" "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=site&only=scripts&skin=monobook&*" >"p99-offline.js"

# ==========================================
# 3. The Master Wget Sync
# ==========================================
echo "Step 2: Starting Wget mirror sync..."
# -m ensures it acts as an incremental mirror
# -e robots=off allows grabbing Magelo profiles
# The regex allows ?pagefrom= pagination, allows Special:Magelo, but strictly blocks tracking loops
wget -k -p -m -nv -nH -X "index.php" \
  --reject-regex ".*(action=|diff=|oldid=|printable=|limit=|sort=|dir=|(Special:|Special%3A)(RecentChanges|WhatLinksHere|Search|UserLogin)|Help:|Help%3A).*" \
  --content-disposition --no-check-certificate -e robots=off -E https://wiki.project1999.com

# ==========================================
# 4. Post-Sync File Renaming (The ? Fix)
# ==========================================
echo "Step 3: Safely renaming dynamic index files..."
# Converts any physical files with a '?' in the name to use an '_' instead so Apache can serve them
find . -type f -name "index.php?*" | while read filepath; do
  newpath="${filepath//\?/_}"
  if [ "$filepath" != "$newpath" ]; then
    mv "$filepath" "$newpath"
  fi
done

# ==========================================
# 5. Localizing Links & YaCy Injection
# ==========================================
echo "Step 4: Applying local customizations to all HTML files..."
find . -type f -name "*.html" -exec sed -i -E \
  -e 's/index\.php\?/index.php_/g' \
  -e 's|href="[^"]*load\.php[^"]*"|href="/p99-offline.css"|g' \
  -e 's|src="[^"]*load\.php[^"]*"|src="/p99-offline.js"|g' \
  -e "s|<form action=\"[^\"]*index\.php\" id=\"searchform\">|<form action=\"https://$YACY_DOMAIN/yacysearch.html\" id=\"searchform\"><input type=\"hidden\" name=\"verify\" value=\"ifexist\"><input type=\"hidden\" name=\"contentdom\" value=\"text\"><input type=\"hidden\" name=\"resource\" value=\"global\"><input type=\"hidden\" name=\"maximumRecords\" value=\"10\">|g" \
  -e 's|<input type="search" name="search"|<input type="search" name="query"|g' \
  -e "s|https://wiki\.project1999\.com|https://$DOMAIN|g" \
  -e "s|http://wiki\.project1999\.com|https://$DOMAIN|g" \
  -e "s|//wiki\.project1999\.com|//$DOMAIN|g" \
  {} +

# ==========================================
# 6. Permissions Enforcement
# ==========================================
echo "Step 5: Enforcing standard web permissions..."
# Ensures Apache can read everything if run as root
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +

echo "--- SYNC COMPLETE ---"
echo "Mirror: https://$DOMAIN"
echo "Search: https://$YACY_DOMAIN"

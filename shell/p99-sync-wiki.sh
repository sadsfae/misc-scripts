#!/bin/bash

# ==========================================
# 1. Configuration & Setup
# ==========================================
WIKI_DIR="/var/www/html/p99wiki"
DOMAIN="p99.funcamp.net"
YACY_DOMAIN="eq.funcamp.net"

# Move into the directory
cd "$WIKI_DIR" || {
  echo "Fatal: Directory $WIKI_DIR not found!"
  exit 1
}

# ==========================================
# 2. Asset Refresh & CSS Hiding
# ==========================================
echo "Step 1: Refreshing global CSS and JS assets..."
wget -qO- "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=mediawiki.legacy.commonPrint%2Cshared%7Cskins.monobook&only=styles&skin=monobook&*" "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=site&only=styles&skin=monobook&*" >"p99-offline.css"
wget -qO- "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=startup&only=scripts&skin=monobook&*" "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=site&only=scripts&skin=monobook&*" >"p99-offline.js"

# Strip out the Login menu and the custom P99 Site Notice paragraph
echo '#p-personal, #siteNotice, #localNotice { display: none !important; }' >>p99-offline.css

# ==========================================
# 3. The Full Wget Mirror Sync
# ==========================================
echo "Step 2: Starting Wget mirror sync..."
# -m ensures it acts as an incremental mirror against the whole site
wget -k -p -m -nv -nH -X "index.php" \
  --reject-regex ".*(action=|diff=|oldid=|printable=|limit=|sort=|dir=|(Special:|Special%3A)(RecentChanges|WhatLinksHere|Search|UserLogin)|Help:|Help%3A).*" \
  --content-disposition --no-check-certificate -e robots=off -E https://wiki.project1999.com

# ==========================================
# 4. Rapid Localizing (Post-Processing)
# ==========================================
echo "Step 3: Applying local customizations to all HTML files..."
find . -type f -name "*.html" -exec sed -i -E \
  -e 's/index\.php\?/index.php_/g' \
  -e 's|<li id="pt-login"[^>]*><a[^>]*>[^<]*</a></li>||g' \
  -e 's|<li id="pt-createaccount"[^>]*><a[^>]*>[^<]*</a></li>||g' \
  -e 's|<li id="pt-anonlogin"[^>]*><a[^>]*>[^<]*</a></li>||g' \
  -e 's|href="[^"]*load\.php[^"]*"|href="/p99-offline.css"|g' \
  -e 's|src="[^"]*load\.php[^"]*"|src="/p99-offline.js"|g' \
  -e "s|<form action=\"[^\"]*index\.php\" id=\"searchform\">|<form action=\"https://$YACY_DOMAIN/yacysearch.html\" id=\"searchform\"><input type=\"hidden\" name=\"verify\" value=\"ifexist\"><input type=\"hidden\" name=\"contentdom\" value=\"text\"><input type=\"hidden\" name=\"resource\" value=\"global\"><input type=\"hidden\" name=\"maximumRecords\" value=\"10\">|g" \
  -e 's|<input type="search" name="search"|<input type="search" name="query"|g' \
  -e "s|https://wiki\.project1999\.com|https://$DOMAIN|g" \
  -e "s|http://wiki\.project1999\.com|https://$DOMAIN|g" \
  -e "s|//wiki\.project1999\.com|//$DOMAIN|g" \
  {} +

# ==========================================
# 5. File Renaming & Permissions
# ==========================================
echo "Step 4: Safely renaming newly paginated files..."
find . -type f -name "index.php?*" | while read filepath; do
  newpath="${filepath//\?/_}"
  if [ "$filepath" != "$newpath" ]; then
    mv "$filepath" "$newpath"
  fi
done

echo "Step 5: Enforcing standard web permissions..."
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +

echo "--- FULL SYNC COMPLETE ---"

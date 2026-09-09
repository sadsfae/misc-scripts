#!/bin/bash

# 1. Setup Variables
WIKI_DIR="/var/www/html/p99wiki"
DOMAIN="p99.funcamp.net"
YACY_DOMAIN="eq.funcamp.net"

# Force the script to move into the target directory before doing anything else
cd "$WIKI_DIR" || exit

echo "Step 1: Collapsing dynamic CSS and JS assets..."
wget -qO- "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=mediawiki.legacy.commonPrint%2Cshared%7Cskins.monobook&only=styles&skin=monobook&*" "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=site&only=styles&skin=monobook&*" > "$WIKI_DIR/p99-offline.css"

wget -qO- "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=startup&only=scripts&skin=monobook&*" "https://wiki.project1999.com/load.php?debug=false&lang=en&modules=site&only=scripts&skin=monobook&*" > "$WIKI_DIR/p99-offline.js"

echo "Step 2: Starting incremental Wget mirror sync..."
# The regex is now tuned to allow pagination (?pagefrom=) but block infinite loops (action=, diff=, etc.)
wget -k -p -m -nv -nH --reject-regex ".*(action=|diff=|oldid=|printable=|limit=|sort=|dir=|RecentChanges|WhatLinksHere|Search|UserLogin|Help:|Help%3A).*" --content-disposition --no-check-certificate -E https://wiki.project1999.com

echo "Step 3: Localizing all assets and internal links..."
find "$WIKI_DIR" -type f -name "*.html" -exec sed -i -E \
  -e 's|href="[^"]*load\.php[^"]*"|href="/p99-offline.css"|g' \
  -e 's|src="[^"]*load\.php[^"]*"|src="/p99-offline.js"|g' \
  -e "s|<form action=\"[^\"]*index\.php\" id=\"searchform\">|<form action=\"https://$YACY_DOMAIN/yacysearch.html\" id=\"searchform\"><input type=\"hidden\" name=\"verify\" value=\"ifexist\"><input type=\"hidden\" name=\"contentdom\" value=\"text\"><input type=\"hidden\" name=\"resource\" value=\"global\"><input type=\"hidden\" name=\"maximumRecords\" value=\"10\">|g" \
  -e 's|<input type="search" name="search"|<input type="search" name="query"|g' \
  -e "s|https://wiki\.project1999\.com|https://$DOMAIN|g" \
  -e "s|http://wiki\.project1999\.com|https://$DOMAIN|g" \
  -e "s|//wiki\.project1999\.com|//$DOMAIN|g" \
  {} +

# now rename index.php stuff
find /var/www/html/p99wiki/ -type f -name "index.php?*" | while read filepath; do mv "$filepath" "${filepath//\?/_}"; done
# update links
find /var/www/html/p99wiki/ -type f -name "*.html" -exec sed -i -E 's/index\.php\?/index.php_/g' {} +

echo "--- SYNC COMPLETE ---"

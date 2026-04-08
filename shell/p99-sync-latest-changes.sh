#!/bin/bash

# ==========================================
# 1. Configuration & Setup
# ==========================================
WIKI_DIR="/var/www/html/p99wiki"
DOMAIN="p99.funcamp.net"
YACY_DOMAIN="eq.funcamp.net"

# Parse arguments for Dry Run mode
DRY_RUN=0
if [[ "$1" == "--dry-run" || "$1" == "-d" ]]; then
  DRY_RUN=1
  echo "======================================================"
  echo " DRY RUN MODE ACTIVATED: No files will be modified."
  echo "======================================================"
fi

# Move into the directory
cd "$WIKI_DIR" || {
  echo "Fatal: Directory $WIKI_DIR not found!"
  exit 1
}

echo "Step 1: Interrogating MediaWiki API for recent changes..."

# Ask the API for the last 500 changes in JSON format.
curl -s "https://wiki.project1999.com/api.php?action=query&list=recentchanges&rclimit=500&rcprop=title&format=json" |
  grep -o '"title":"[^"]*"' |
  cut -d'"' -f4 |
  tr ' ' '_' |
  sort -u |
  awk '{print "https://wiki.project1999.com/"$0}' >smart_sync_urls.txt

# Safety check: Did we actually find any changes?
if [ ! -s smart_sync_urls.txt ]; then
  echo "No recent changes detected. Sync complete!"
  rm -f smart_sync_urls.txt
  exit 0
fi

FILE_COUNT=$(wc -l <smart_sync_urls.txt)

# ==========================================
# 2. Dry Run Check
# ==========================================
if [ $DRY_RUN -eq 1 ]; then
  echo "Found $FILE_COUNT updated pages. If this were a real run, Wget would download:"
  echo "------------------------------------------------------"
  cat smart_sync_urls.txt
  echo "------------------------------------------------------"
  echo "Dry run complete. Run without flags to execute sync."
  rm -f smart_sync_urls.txt
  exit 0
fi

echo "Found $FILE_COUNT updated pages. Initiating targeted download..."

# ==========================================
# 3. The Targeted Wget Strike
# ==========================================
echo "Step 2: Fetching updated files and their prerequisites..."
wget -k -p -nv -nH -X "index.php" \
  --content-disposition --no-check-certificate -e robots=off -E \
  -i smart_sync_urls.txt

# ==========================================
# 4. Rapid Localizing (Post-Processing)
# ==========================================
echo "Step 3: Applying local customizations to newly updated files..."
find . -type f -name "*.html" -mtime -1 -exec sed -i -E \
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
# 5. File Renaming & Permissions
# ==========================================
echo "Step 4: Safely renaming newly paginated files..."
find . -type f -name "index.php?*" -mtime -1 | while read filepath; do
  newpath="${filepath//\?/_}"
  if [ "$filepath" != "$newpath" ]; then
    mv "$filepath" "$newpath"
  fi
done

echo "Step 5: Enforcing standard web permissions on updated files..."
find . -type f -mtime -1 -exec chmod 644 {} +

# Cleanup our hit-list
rm -f smart_sync_urls.txt

echo "--- SMART SYNC COMPLETE ---"

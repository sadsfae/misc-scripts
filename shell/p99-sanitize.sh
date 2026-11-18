#!/bin/bash
# /root/p99-sanitize.sh - strip dead MediaWiki chrome + dead .php/index.php/action= links
# from the p99 static mirror. Idempotent. Run after the sync localization pass.
# Usage: p99-sanitize.sh            (all *.html)
#        p99-sanitize.sh -mtime -1  (recently-updated only, for incremental sync)
#
# Reasons for BRE (no -E) and @ as the s/// delimiter:
#   - GNU sed's \(a\|b\) alternation is the reliably-supported form; a plain \|
#     with -E silently failed on some alternatives in testing.
#   - using | as the s/// delimiter collides with the \| alternation, so use @.
#
# What it removes (dead in a flat mirror, no PHP):
#   - MediaWiki page-action tabs (ca-talk / ca-viewsource / ca-history / ca-edit /
#     ca-watch / ca-move / ...) but keeps the live "Page" tab (ca-nstab-main).
#   - personal-tools items (pt-*) and the toolbox (p-tb) items (t-*) which point at
#     Special: / index.php?action= / oldid= / printable= - all dead.
#   - the dead n-Random-Page sidebar link (other n-* sidebar nav links are live and kept).
#   - any <a>/<link> whose href carries a dead MediaWiki param (action=|oldid=|diff=|
#     feed=|printable=|api.php|UserLogin|type=signup|WhatLinksHere|RecentChanges|Help:|
#     Special:Search|Special:Random|Special:UserLogout). Content links to local .html,
#     the index.php_title=...&pagefrom= pagination links, and external links are kept.
#   - the "Retrieved from <a...oldid=...>" printfooter (dead oldid link).
#
# Leaves the (now-invisible, empty) chrome container shells in place; they render nothing.
WIKI_DIR="${WIKI_DIR:-/var/www/html/p99wiki}"
EXTRA="${1:-}"

find "$WIKI_DIR" -type f -name "*.html" $EXTRA -exec sed -i \
  -e '/^[[:space:]]*<li[[:space:]]*id="\(ca-talk\|ca-viewsource\|ca-history\|ca-edit\|ca-watch\|ca-unwatch\|ca-move\|ca-delete\|ca-protect\|ca-addsection\|pt-login\|pt-createaccount\|pt-anonlogin\|pt-logout\|pt-preferences\|pt-watchlist\|pt-userpage\|pt-mytalk\|pt-mycontris\|t-whatlinkshere\|t-recentchangeslinked\|t-specialpages\|t-print\|t-permalink\|t-info\|t-cite\|t-contributions\|t-upload\|t-blockip\|t-emailuser\|t-trackbacklink\|n-Random-Page\)"/d' \
  -e 's@<a[^>]*href="[^"]*\(action=\|oldid=\|diff=\|feed=\|printable=\|api\.php\|UserLogin\|type=signup\|WhatLinksHere\|RecentChanges\|Special:Search\|Special:Random\|Special:UserLogout\)[^"]*"[^>]*>[^<]*</a>@@g' \
  -e 's@<link[^>]*href="[^"]*\(\.php\|action=\|oldid=\|diff=\|feed=\|UserLogin\|RecentChanges\|WhatLinksHere\)[^"]*"[^>]*>@@g' \
  -e 's@</div><div class="printfooter">@</div>@g' \
  -e '/^[[:space:]]*Retrieved from/d' \
  -e '/^[[:space:]]*<span[^>]*class="plainlinks"[^>]*>[[:space:]]*<\/span>/d' \
  {} +

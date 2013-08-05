#!/bin/sh
# this generates a generic virtual host container based on the values
# you have generated from the vhost_user_setup.sh script
# run this after vhost_user_setup script and use those values
# output should be copied to a vhosts file and placed in /etc/httpd/conf/vhosts/ as like "site.conf"
# at end of your /etc/httpd/conf/httpd.conf file place a line like "Include conf/vhosts/*" 

echo "Enter vhost name (www.yoursite.com)"
siteFQDN=$(head -n1)
echo "Enter vhost short name (yoursite.com)"
siteShortFQDN=$(head -n1)
echo "Enter vhost user's group (same as homedir name)"
vhostGroup=$(head -n1)

cat <<Endofmessage
------- BEGIN VIRTUAL HOST -------
#$siteFQDN virtual host container
NameVirtualHost *:80

#
<VirtualHost *:80>
#
ServerName $siteFQDN 
ServerAlias $siteShortFQDN 
DocumentRoot /home/$vhostGroup/public_html/
LogFormat "%h %l %u %t \"%r\" %>s %b" combined
CustomLog /home/$vhostGroup/logs/${siteShortFQDN}_access_log combined
ErrorLog /home/$vhostGroup/logs/${siteShortFQDN}_error_log
# redirect any of our aliases back to original site
<IfModule mod_rewrite.c>
        RewriteEngine on
        RewriteRule  /BADSUBDIRHERE/(.*)$       http://$siteFQDN/$1    [R,L]
 </IfModule>
</VirtualHost>
------- END VIRTUAL HOST -------
Endofmessage

#!/bin/sh
# create a local user/group for hosting a virtual host out of public_html
# use this in combination with vhost_maker.sh and run prior, remembering your values
# this needs to be run as root

# check if the user is root, if not warn and quit
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# if everything is ok, proceed..

echo "-------------------"
echo "vhost user name (i.e. bubbaweb for bubba)"
echo "-------------------"

vhostuser=$(head -n1)

echo "-------------------"
echo "Checking if user exists..."
echo "-------------------"
echo "                   "

# define virthostuser now that we've prompted for it
usernotvalid=$(cat /etc/passwd | grep $vhostuser |wc -l)

# check if user exists, if not continue 
if [ "$usernotvalid" = "1" ];
  then echo "< --- User exists, quitting! --- >" && exit 1
   else echo "< --- User is valid, proceeding --- >"
fi

echo "                   "
echo "-------------------"
echo "vhost users group (websitename minus www i.e. bubba.com)"
echo "-------------------"

vhostgroup=$(head -n1)

echo "-------------------"
echo "Checking if group exists..."
echo "-------------------"
echo "                   "

# define vhostgroup now that its been prompted
groupnotvalid=$(cat /etc/group | grep $vhostgroup |wc -l)

# check if group exists, if so quit
if [ $groupnotvalid = "1" ];
  then echo "< --- Group already exists, quitting! --- >" && exit 1
   else echo "< --- Group is valid, proceeding --- >"
fi

# create groups
echo "                             "
echo "-----------------------------"
echo "creating group $vhostgroup..."
echo "-----------------------------"
echo "                             "

groupadd $vhostgroup
echo "-----------------------------"
echo "creating user: $vhostuser.."
echo "-----------------------------"
echo "                             "

useradd -g $vhostgroup -m -d /home/$vhostgroup $vhostuser

echo "-----------------------------"
echo "creating home for $vhostuser.."
echo "-----------------------------"
echo "                             "

# add apache to the new vhost group for httpd perms
echo "-----------------------------"
echo "Adding apache and sysadmins to $vhostgroup"
echo "-----------------------------"

usermod -a -G $vhostgroup apache

# create the users public_html and set permissions
echo "                             "
echo "-----------------------------"
echo "Creating users public_html..."
echo "-----------------------------"
echo "                             "

mkdir -p /home/$vhostuser/public_html
mkdir -p /home/$vhostuser/logs

echo "-----------------------------"
echo "Setting ownership permissions.."
echo "-----------------------------"
echo "                             "

chown -R $vhostuser.$vhostgroup /home/$vhostuser

echo "-----------------------------"
echo "Setting proper permissions for public_html.."
echo "-----------------------------"

chmod 711 /home/$vhostuser
chmod 755 /home/$vhostuser/public_html

echo "                             "
echo "\o/ Done! \o/" 
echo "                             "

userid=$(getent passwd $vhostuser | awk -F ":" '{print $3}')

echo "<-------- Summary ---------->"
echo "username:  $vhostuser        "
echo "usergroup: $vhostgroup       "
echo "userid:    $userid           "
echo "www root:  /home/$vhostuser/public_html"
echo "<--------------------------->"
echo "                             "
echo "(Note: now run vhost_maker.sh to create vhost template)"
echo "                                                       "

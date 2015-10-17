#!/bin/bash
# This is a workaround for a mysterious "something went wrong" issue
# This is specifically for the Trystack.org public cloud
# http://trystack.org
# This should be used when a user asks about it on IRC or other special purposes.
# CAUSE: Something in Facebook API or callback code
# SYMPTOM: Tenant gets created but user creation fails or never finishes
# FIX: create a user for them, link to their existing tenant
#### THINGS YOU NEED
# - email of user
# - facebook profile ID
# first we need to have the facebook ID.  This might be easier done manually on facebook.com ... e.g.:
# 1) facebook search for "bob.demo.12"
# 2) select the found user, e.g.:  https://www.facebook.com/john.demo.12?ref=br_rs
# 3) hover over the profile picture and right-click open in new tab:
#    https://www.facebook.com/profile/picture/view/?profile_id=123456789
# 4) verify that the profile ID leads to the same account with:
#    https://www.facebook.com/profile.php?id=123456789
#
#####

echo -n "Enter facebook profile ID: "
read id
echo -n "Enter email address to use: "
read emailid

# next verify that the tenant exists, and the user does not.  This is the
# typical failure scenario.

source /root/keystonerc_admin

get_id() {
  echo `"$@" | awk '/id / {print $4}'`
}

create_tenant_user() {

set -x

tenant_name=$1
email_id=$2
tenant_id=$(get_id openstack project show facebook${tenant_name})
randpass=$(date +%s| base64 | cut -c1-16)

if [[ -z $tenant_id ]]
then
	echo "Unable to find tenant ID. exiting."
        return 1
fi

openstack user create --password $randpass --email $email_id --project $tenant_id facebook$tenant_name

set +x

}

function run_fix() {
  userid=$1
  emailid=$2
  echo ==== need to create user "facebook"$userid
  echo ==== need to associate user with tenant
  create_tenant_user $userid $emailid
  return 0
}

if [ "$(openstack project list | grep $id)" ]; then
  if [ -z "$(openstack user list | grep $id)" ]; then
    echo tenant $id exists but user does not.
    run_fix $id $emailid
  else
    echo both tenant and id exist. exiting.
    exit 0
  fi
else
  echo tenant does not exist. exiting.
  exit 0
fi

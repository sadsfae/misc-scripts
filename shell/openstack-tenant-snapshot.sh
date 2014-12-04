#!/bin/sh
# This tool takes snapshots of each users instance as that user.
# It also tries to link a user without an associated project to a project
# with the same name as that user if it exists.
# We dump the database first, set users password to something simple via
# a known salt+hash obtained via a perl(crypt) call, then creates a temporary
# keystonerc and goes through as each user to snapshot instances that are running
# or shutdown.  Lastly, we inject the original user DB back in.
# This was used originally for a Havana -> Icehouse upgrade but may be of
# use to others.
# original credit goes to Kambiz Aghaiepour
# perl crypt call to obtain salt+hash:
# perl -e 'print crypt("password","\$6\$rounds=40000\$") . "\n"'

TMPFILE=`mktemp /tmp/mysqlXXXXXXX`
SCRATCHFILE=`mktemp /tmp/scratchXXXXXXX`
DEFAULT_PASSWORD='$6$rounds=40000$$KvWVosYOtuVR9hQxp4nd345iifVhmE3fpp4LImnQmZXQMofw65Qb/PWIJAUkEEWk1ezairsEeYU4REIQ4Tigb/'

function check_database() {
  true;
  if [ "`echo show databases\; | mysql 2>/dev/null  | grep keystone`" = "keystone" ]; then
	  :
  else
	  echo "keystone database not found locally. Horsefeathers!."
	  exit 1
  fi

  if [ -x /usr/bin/mysqldump ]; then
	  :
  else
	  echo "/usr/bin/mysqldump not found.  Fiddlesticks!"
	  exit 1
  fi
}

function user_list() {
  echo "select name from user;" | mysql keystone | egrep -v '^name|^^admin|^cinder|^nova|^neutron|^ceilometer|^heat|^swift|^heat-cfn|^glance'
}

function tenant_save_passwords() {
  true;
  mysqldump --single-transaction --events --master-data --database keystone  > $TMPFILE
}

function tenant_set_passwords() {
  true;
  myuserlist=$(user_list)

  for user in $myuserlist ; do
	  echo 'update user set password = "'$DEFAULT_PASSWORD'" where name = "'$user'";' | mysql keystone
  done

}

function tenant_restore_passwords() {
  true;
  mysql --one-database keystone < $TMPFILE
}

function tenant_keystonerc_create() {
  true;
  mkdir /root/keystonerc.d/ 2>/dev/null
  myuserlist=$(user_list)
  for user in $myuserlist ; do
	  projectid=$(echo "select default_project_id from user where name = \"$user\";" | mysql keystone | grep -v default_project_id)
	  tenantname=$(echo "select name from project where id = \"$projectid\";" | mysql keystone | egrep -v ^name)
	  if [ -z "$tenantname" ]; then
		echo === user $user has no default tenant set ...
		trytenant=$(keystone tenant-get $user 2>/dev/null | grep id | awk '{ print $4 }')
		if [ "$trytenant" ] ; then
			echo ===== setting user to tenant $user ...
			echo "update user set default_project_id = \"$trytenant\" where name = \"$user\";" |  mysql keystone
			tenantname=$trytenant
		fi
	  fi

	  cat > /root/keystonerc.d/$user <<EOF
export OS_USERNAME=$user 
export OS_TENANT_NAME=$tenantname   
export OS_PASSWORD=changeme
export OS_AUTH_URL=http://192.168.1.1:35357/v2.0/
export PS1='[\u@\h \W(openstack_admin)]\$ '
EOF
  done
}

function user_nova_list() {
  true;
  myuserlist=$(user_list)

  mkdir /root/nova.d/ 2>/dev/null
  for user in $myuserlist ; do
	  if [ -f /root/keystonerc.d/$user ]; then
		  source /root/keystonerc.d/$user
		  nova list > /root/nova.d/nova-list-$user
	  fi
  done
}

function tenant_snap_create() {
  true;
  user_nova_list
  myuserlist=$(user_list)
  for user in $myuserlist ; do
	source /root/keystonerc.d/$user
	if [ -f /root/nova.d/nova-list-$user ]; then
		egrep -v '^\+|ID' /root/nova.d/nova-list-$user > $SCRATCHFILE
		for vm in $(awk '{ print $2 }' $SCRATCHFILE) ; do
			echo ===== attempting to snapshot : $(grep $vm $SCRATCHFILE) ====
			vmname=$(grep $vm $SCRATCHFILE |awk -F\| '{ print $3 }' | sed 's/^ \(.*\) $/\1/g')
			newname="$vmname"_20141203
			nova image-create "$vm" "$newname"
		done
	fi
  done
}

function cleanup() {
  true;
  echo backup may be saved in $TMPFILE
  rm -f $SCRATCHFILE
}

function main() {

  true;
  check_database
  tenant_save_passwords
  tenant_set_passwords
  tenant_keystonerc_create
  tenant_snap_create
  tenant_restore_passwords
  cleanup
}

main

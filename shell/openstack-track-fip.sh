#!/bin/bash
# track down a tenant by floating IP address
# this will display who currently has a floating IP address
# based on either router-list or floatingip-list output.

fip_address=$1

# print usage if variable isn't specified
if [[ $# -eq 0 ]]; then
        echo "USAGE: ./openstack-track-fip.sh \$IPADDRESS"
        echo "       ./openstack-track-fip.sh 128.136.179.9"
        echo "                                          "
        exit 1
fi

# source keystonerc
source /root/keystonerc_admin

track_ip() {
        targrouter=$(neutron router-list | grep -w $fip_address | awk '{print $2}')
        targfipid=$(neutron floatingip-list | grep -w $fip_address | awk '{print $2}')
        
# if there's no fip, no need to look further
if [ -z "$targrouter" -a -z "$targfipid" ]; then
	echo "IP address not found, or unassociated"
	echo "                                     "
	exit 1
fi

# floating ip will either show against router-show or floating-ip list
if [ -z $targfipid ]; then
	targtenant=$(neutron router-show $targrouter | grep tenant_id | awk '{print $4}')
        targname=$(openstack project show $targtenant | grep name | awk '{print $4}')
        targmail=$(openstack user show $targname | grep email | awk '{print $4}')
else
        targtenant=$(neutron floatingip-show $targfipid | grep tenant_id | awk '{print $4}')
        targname=$(openstack project show $targtenant | grep name | awk '{print $4}')
        targmail=$(openstack user show $targname | grep email | awk '{print $4}')
fi

cat << EndofMessage

########### OpenStack IP Sleuth 3000 ###########
#                                               
# $fip_address currently resolves to:                     
#                                               
#-----------------------------------------------
# Tenant   = $targtenant                        
# Username = $targname                          
# Email    = $targmail                          
#-----------------------------------------------
#                                               
################################################

To disable the account run:
------------------------------------------------

source /root/keystonerc_admin
openstack user set $targname --disable


EndofMessage
}

track_ip

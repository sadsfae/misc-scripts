#!/bin/sh
# check/create bridged interface for use with openvswitch if it doesn't exist
# assumes your primary interface is called "bond0"

check_br_ex_exist()
{  # check if there's a bridged interface
   /sbin/ifconfig -a | grep br-ex | wc -l
}

create_br_ex_int()
{  # bring up br-ex
   echo "starting openvswitch service.." 
   chkconfig --add openvswitch ; service openvswitch start
   echo "creating external bridge interface.."
   cp /etc/sysconfig/network-scripts/ifcfg-bond0 /etc/sysconfig/network-scripts/ifcfg-br-ex 
   sed -i 's/IPADDR/#IPADDR/g' /etc/sysconfig/network-scripts/ifcfg-bond0
   sed -i 's/NETMASK/#NETMASK/g' /etc/sysconfig/network-scripts/ifcfg-bond0
   sed -i 's/DEVICE=bond0/DEVICE=br-ex/g' /etc/sysconfig/network-scripts/ifcfg-br-ex
   sed -i 's/BONDING_OPTS/#BONDING_OPTS/g' /etc/sysconfig/network-scripts/ifcfg-br-ex
   echo "adding external bridge interface to ovs.."
   ovs-vsctl add-br br-ex ; ovs-vsctl add-port br-ex bond0 && /sbin/service network restart
}

# sanity check to ensure user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# create br-ex if it doesn't exist
br_ex_exist=$(check_br_ex_exist)

case $br_ex_exist in
'1')
   echo "external bridge interface exists, quitting"
   exit 1
;;
'0')
   echo "external bridge interface doesn't seem to exist."
   create_br_ex_int
;;
esac

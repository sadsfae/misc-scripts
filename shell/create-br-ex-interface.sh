#!/bin/sh
# check/create bridged interface for use with openvswitch if it doesn't exist
# assumes your primary interface is called "bond0"
# assumes you're running a Red Hat based distribution

detect_os()
{  # EL6 kernel will be 2.6.x kernel, EL7+ or Fedora will be 3.x
   kernelver=`uname -a | awk '{print $3}' | awk -F "." '{print $1}'`
}

os_version=$(detect_os)

start_ovs()
{
case $os_version in
'3')
	systemctl enable openvswitch.service
	systemctl start openvswitch.service
;;
'2')
	chkconfig --add openvswitch
        service openvswitch start
;;
esac
}

check_br_ex_exist()
{  # check if there's a bridged interface
   /sbin/ifconfig -a | grep br-ex | wc -l
}

create_br_ex_int()
{  # bring up br-ex
   echo "starting openvswitch service.." 
   start_ovs
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

#!/bin/sh
# loop through all oslab nodes and start or stop services
# do the neutron and controller node last.

oslab_nodes=( host01.oslab.openstack.example.com \
             host07.oslab.openstack.example.com \
             host08.oslab.openstack.example.com \
             host09.oslab.openstack.example.com \
             host10.oslab.openstack.example.com \
             host11.oslab.openstack.example.com \
             host12.oslab.openstack.example.com \
             host13.oslab.openstack.example.com \
             host14.oslab.openstack.example.com \
             host15.oslab.openstack.example.com \
             host16.oslab.openstack.example.com \
             host03.oslab.openstack.example.com \
	     host02.oslab.openstack.example.com \
)

oslab_stop_services() {
   ssh root@$x "openstack-service stop" 2>/dev/null
}

oslab_start_services() {
   ssh root@$x "openstack-service start" 2>/dev/null
}

case "$1" in
start)
   for x in ${oslab_nodes[@]}; do
   oslab_start_services; done           	
   ;;
stop)
   for x in ${oslab_nodes[@]}; do
   oslab_stop_services; done
   ;;
*)
   echo "Usage: {start|stop}"
esac

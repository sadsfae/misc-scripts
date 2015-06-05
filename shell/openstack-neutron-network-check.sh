#!/bin/bash
# monitoring tool that spins up an instance, assigns floating ip
# and tests connectivity.
# designed to be utilized by a monitoring system like nagios, sensu etc.
# external network is: c63b3ed6-3819-48c5-a286-d8727ad8c985
# cirros image is:  7006f873-25ca-48c7-8817-41f29506f88b

function get_id () {
  echo `"$@" | awk '/ id / {print $4}'`
}

function get_ip_address () {
  echo `"$@" | awk '/ floating_ip_address / {print $4}'`
}

function cleanup () {
  if [ -n "$floatingip_id" ]; then
    neutron floatingip-delete "$floatingip_id" 1>/dev/null 2>&1
  fi
  nova delete  ${vm_id} 1>/dev/null 2>&1
  exit $exitcode
}

vm_name=test-$$-$(date +%s)
image='7006f873-25ca-48c7-8817-41f29506f88b'
flavor=m1.small

keystonerc=/etc/nagios/keystonerc_admin

source $keystonerc

exitcode=0

BOOT=$(nova boot --flavor=${flavor} --image=${image} ${vm_name} 2>&1) 
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$BOOT"
  exitcode=2
  cleanup
fi

vm_id=$(get_id nova show ${vm_name})
sleep 5

loopcount=0
while ! nova show ${vm_id} | grep 'ACTIVE' 2>&1 > /dev/null
do
  sleep 3
  loopcount=$(expr $loopcount + 1)
  if [ $loopcount -gt 200 ]; then
    # it means 10 minutes has passed
    exitcode=2
    nova delete  ${vm_id} 1>/dev/null 2>&1
    echo "Neutron ERROR: took too long to be ACTIVE"
    cleanup
  fi
done

FIP=$(neutron floatingip-create c63b3ed6-3819-48c5-a286-d8727ad8c985 2>&1)
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$FIP"
  exitcode=2
  cleanup
fi

floatingip=$(get_ip_address echo "$FIP")
floatingip_id=$(get_id echo "$FIP")

FLOATINGIP=$(nova add-floating-ip ${vm_id} ${floatingip} 2>&1)
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$FLOATINGIP"
  exitcode=2
  cleanup
fi

# we need to give the instance a chance to initialize, and neutron to set things up
# sleep for a minute

sleep 120

PING=$(ping -c 3 $floatingip 2>&1)
rp=$?

if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$PING"
  exitcode=2
  cleanup
fi

FLOATINGIPRM=$(nova remove-floating-ip ${vm_id} ${floatingip} 2>&1)
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$FLOATINGIPRM"
  exitcode=2
  cleanup
fi

nova delete  ${vm_id} 1>/dev/null 2>&1
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo "Neutron ERROR: Failed to delete VM"
  exitcode=2
  cleanup
fi

if [ -n "$floatingip_id" ]; then
  neutron floatingip-delete "$floatingip_id" 1>/dev/null 2>&1
  rp=$?
  if [[ "$rp" -ne 0 ]]
  then
    echo "Neutron ERROR: Failed to delete floating_ip"
    exitcode=2
    cleanup
  fi
fi

echo "Neutron OK: Floating IP responding"
exitcode=0
cleanup

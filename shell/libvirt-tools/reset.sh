#!/bin/sh
# calls reset-images.sh and virsh to reset environment

cd /var/lib/libvirt/images/

for h in host-01 host-02 host-03 ; do
  virsh destroy $h
  /root/VIRT/reset-images.sh $h
done

virsh net-destroy default
virsh net-start default

for h in host-01 host-02 host-03 ; do
  virsh start $h
done


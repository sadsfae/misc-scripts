libvirt-tools
=============
a simple tool to easily reset VMs to a vanilla state for testing

**Requirements**
  - libvirt
  - qemu-kvm 
  - qemu-img
  - libguestfs-tools
  - Assumes an EL-based Hypervisor

**Instructions**
  - Preparation
    * Install CentOS/RHEL7 on Libvirt locally or on a hypervisor
    * Save the qcow2 image (this is your gold copy)
    * Name it ```centos7-base.qcow2```
    * Delete the VM (saving the image)

  - Creation
    * Create a number of VM qcow2 images using the above image as the backing
      file.
```
cd /var/lib/libvirt/images/
cp -p /var/lib/libvirt/images/centos7.qcow2 /var/lib/libvirt/images/centos7-base.qcow2
rm -f centos7.qcow2 
qemu-img create -b `pwd`/centos7-base.qcow2 -f qcow2 host-01.qcow2
qemu-img create -b `pwd`/centos7-base.qcow2 -f qcow2 host-02.qcow2
qemu-img create -b `pwd`/centos7-base.qcow2 -f qcow2 host-03.qcow2
```

**Build your Test Fleet**
  - Create 3 VMs (or as many as you need in your test env) using virt-manager
    For each, use a pre-existing disk image and use each of the above
    disk image files.

**Usage**
  - Edit the guests array inside ```vm-reset.sh``` to your liking
```
guests=(
   ["host-01"]="81"
   ["host-02"]="82"
   ["host-03"]="83"
   )
```
  - Add your public SSH key here in ```vm-reset.sh```
```
   # ADD YOUR PUB SSH KEY HERE
   echo ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   # END SSH PUB KEY
```
  - Run ```vm-reset.sh``` as root to reset your environments.


**Issues**
  - Occasionally you'll get a VM in a non-bootable state or grub error
    - **Fix** just force power off and power on again.

vm-sandbox-tool
===============
a simple tool to easily reset VMs to a vanilla state for testing

**Requirements**
  - libvirt
  - qemu-kvm 
  - qemu-img
  - libguestfs-tools
  - An EL-based Hypervisor

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
  - Create 3 VMs (or as many needed in your test environment) via virt-manager
    - Use the ```import existing disk image``` option for each of the above qcow2 images you just created.

![virt-manager](/shell/vm-sandbox-tool/image/virt-manager.png?raw=true)

**Prep the Tool**
  - Edit the guests array inside ```vm-reset.sh``` to your liking
    - e.g. replace host-01 with whatever hostname you chose if it's different.
```
guests=(
   ["host-01"]="81"
   ["host-02"]="82"
   ["host-03"]="83"
   )
```
  - Insert your public SSH key in ```vm-reset.sh``` replacing the MYPUBKEY string.
    - Substitute the name of your public key below if it's not ```id_rsa.pub```
```
sed -i "s,\(.*echo.*\)ssh-rsa MYPUBKEY\(.*authorized_keys$\),\1$(cat ~/.ssh/id_rsa.pub)\2,g" ./vm-reset.sh
```
**Usage**
  - Run ```sudo ./vm-reset.sh``` to reset your environments quickly.

**Issues**
  - Occasionally you'll get a VM in a non-bootable state or grub error
    - **Fix** just force power off and power on again.

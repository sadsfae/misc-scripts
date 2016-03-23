#!/bin/sh
# resets your VM image and sets up network and ssh keys
# add your key below

BASE=centos7-base.qcow2

function do_in_chroot {

if [ ! -d $1/tmp ]; then
  mkdir $1/tmp
fi

# use chroot to perform these tasks
cat > $1/tmp/do_in_chroot.sh <<EOS
#!/bin/sh

function content_update {
    name=\$1
    number=\$(echo \$name | awk -F- '{ print \$2 }')
    octet=\$(expr 80 + \$number)
    myip=192.168.122.\$octet

    cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
NAME="eth0"
NM_CONTROLLED="no"
DEVICE="eth0"
IPADDR="\$myip"
NETMASK="255.255.255.0"
GATEWAY="192.168.122.1"
DNS1="192.168.122.1"
EOF
   for h in \$(seq -w 1 3) ; do
     echo 192.168.122.\$(expr 80 + \$h) host-\$h.int host-\$h >> /etc/hosts
   done
   echo \$name > /etc/hostname
   echo GATEWAY=192.168.122.1 >> /etc/sysconfig/network
   echo SELINUX=permissive > /etc/sysconfig/selinux
   echo SELINUXTYPE=targeted >> /etc/sysconfig/selinux
   mkdir /root/.ssh/
   echo ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXYOURKEYHEREtWwWJ1cRqG3wn7CEqlItiankKdqd+8eZHTGgmBft761il8eRkwNHIFrW+jPzOL8MdPOK66TXUo0myNO/                 9XhjiXtwR4VkANjAqJUFXTkgSXj9nz0rkrHGVYYWvPBvg5KiZm5/ba+ndvyQWc5vDhv8dIKo17uZ5DC6DOcCQs4y6QhYxxVAiqIZaFeFkgRw4Ebkx+MhZ1VrVByOC2PZtj2drwGAa7ItX2i4idIaKTRBI9pehL4ay4NGbzdUeEP304XTukO8A/         q0rCstZEGLqxXgzTaAXTI6DJ0iS8Y0QNk5vwnxBvDBE2oOuZFguQFyNAOkvy+61Tnp6waE05Ss/ZU3J861+fiCJJ1o3waas80qOAIwVTaIwGQ/FTJngZutRcLkdTC21+qaRbW9ZbTIG+bUp1NKAhj84HSsNc8CTcwNEcv8nwi0Cy4ZXY88+            DcO5n6CmFFOm7sXTr0umrhBsKThhkCfFrzN8YTuu3KOcr+vVgZWcEJG+vRSXyl3onFLe+f24Xm77cBE5qNleFns7hkPZxRqEznCkznSumxxdSxbAB9mb2vP3uy1qzk3yQsifatzX3qANWrNgjQlALFXEf95woncUY+VA95Y028YM0/ojpi57jq7wHImh9iqzli20G9RE= wfoster@example.com
   chmod 700 /root/.ssh
   chmod 600 /root/.ssh/authorized_keys
}

content_update \$1

EOS
chmod 755 $1/tmp/do_in_chroot.sh
echo ============================
cat $1/tmp/do_in_chroot.sh
echo ============================

}

function rebuild {
    rm -f $1.qcow2
    # create the overlay
    qemu-img create -b `pwd`/$BASE -f qcow2 $1.qcow2
    # create dir to mount the overlay and update configs
    mkdir /mnt-tmp
    # mount the overlay
    guestmount -a $1.qcow2 -i --rw /mnt-tmp
    do_in_chroot /mnt-tmp
    chroot /mnt-tmp /tmp/do_in_chroot.sh $1
    umount /mnt-tmp
    rmdir /mnt-tmp
}

rebuild $1

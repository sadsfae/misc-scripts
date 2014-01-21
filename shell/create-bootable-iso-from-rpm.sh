#!/bin/sh
# this is used for building new PXE capable ISO images from RHEVH
# but could be used or modified to be used to create bootable ISO's from a remote source.
# first checks if there are any changes to your local copy (in this case an rpm).
# in this particular example we're syncing the latest RHEV-H RPM from a builder, exploding
# it and calling livecd-iso-to-pxeboot to create bootable media then copying the PXE substructure
# into Foreman for provisioning.
# https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Virtualization_for_Servers/2.1/html/5.4-2.1_Hypervisor_Deployment_Guide/sect-Deployment_Guide-Preparing_Red_Hat_Enterprise_Virtualization_Hypervisor_installation_media-Deploying_RHEV_Hypervisors_with_PXE_and_tftp.html
# requires livecd-tools package
# run from cron via: * 14 * * * /root/create-bootable-iso-from-rpm.sh > /var/log/scalelab-rhevh-create.log 2>&1

sourcebuild='location.to.remote.rsync.host'
builddate=$(/bin/date +%Y%m%d%H%M)
localpxedir='/srv/distro/RHEV-H/'
localbuilddir='/srv/distro/RHEV-H-rpm'
rpmfile=`rsync -l rsync://$sourcebuild/rhev-hypervisor*.rpm | awk '{print $5}'`
newbuild=`rsync -dn --delete rsync://$sourcebuild/rhev-hypervisor*.rpm /srv/distro/RHEV-H-rpm/ | grep rhev-hypervisor | wc -l`
getnewbuild=`rsync -dr --delete rsync://$sourcebuild/$rpmfile $localbuilddir/`

build_rhevh()
{  # function to call livecd-tools and build PXE substructure
   cd $localbuilddir
   rpm2cpio $localbuilddir/$rpmfile | cpio -idmv
   livecd-iso-to-pxeboot ./usr/share/rhev-hypervisor/rhevh-*.iso
   cp $localbuilddir/tftpboot/initrd0.img /var/lib/tftpboot/boot/RHEV-H-Latest-initrd.img
   cp $localbuilddir/tftpboot/vmlinuz0 /var/lib/tftpboot/boot/RHEV-H-Latest-vmlinuz
   rm -rf $localbuilddir/{tftpboot,usr}
}

case $newbuild in
'0')
   echo "no new builds available on $builddate, quitting!"
;;
esac

case $newbuild in
'1')
   echo "creating a new build based on $builddate RPM source"
   $getnewbuild
   build_rhevh
;;
esac

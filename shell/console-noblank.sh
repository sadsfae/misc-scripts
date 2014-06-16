#!/bin/sh
# run once to disable console blanking
# RHEL7/Fedora = /etc/default/grub and grub2-mkconfig -o /boot/grub2/grub.cfg
# RHEL6 = /boot/grub/grub.conf

detect_os()
{  # EL6 kernel will be 2.6.x kernel, EL7+ will be 3.x
   kernelver=`uname -a | awk '{print $3}' | awk -F "." '{print $1}'`
}

detect_os

check_blank()
{  # check if settings are already applied
case $kernelver in
'2')
   setting=`cat /etc/grub.conf | grep consoleblank | wc -l`
   if [ $setting -ne 0 ]; then
      echo "Setting already active, quitting!"
      exit 1
   fi
;;
'3')
   setting=`cat /etc/default/grub | grep consoleblank | wc -l`
   if [ $setting = "1" ]; then
      echo "Setting already active, quitting!"
      exit 1
   fi
;;
esac
}

set_consoleblank()
{   # set the consoleblank=0 setting
case $kernelver in
'2')
     sed -i 's/rhgb quiet/rhgb consoleblank=0 quiet/g' /etc/grub.conf
     echo "grub.conf modified, reboot to take effect"
;;
'3')
     sed -i 's/rhgb quiet/rhgb quiet consoleblank=0/g' grub
     echo "grub2 config modified, regenerating kernel initrd.."
     grub2-mkconfig -o /boot/grub2/grub.cfg
     echo "you will need to reboot for changes to take effect"
;;
esac
}

# run the check function
check_blank
# run the console blanking function
set_consoleblank

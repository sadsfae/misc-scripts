#!/bin/bash
# sync remote VM's somewhere and timestamp them
# 0 6 * * 2 would be once a week on tue at 6am
timestamp=$(date +%Y%m%d%H%M)
rsync_cmd="rsync -av --progress -e ssh"
# hypervisor sources
rsync_src_ls="root@yourhost1:/home/virt"
rsync_src_ps="root@yourhost2:/srv/virt"
rsync_dst="$HOME/VM_BACKUP/images"
# VM lists
vm_ls=("vm1.qcow2" "vm2.img" "vm3.qcow2")
vm_ps=("vm4.img" "vm5.img")

function sync_vm_host1 {
    echo "$timestamp - START syncing HOST1 VM to PLACE" >> "$HOME/Documents/vm-sync-to-remote.log"
    for vm in "${vm_ls[@]}";
    do $rsync_cmd $rsync_src_ls/$vm $rsync_dst/$vm-$timestamp;
    done
    echo "$timestamp - END syncing HOST1 VM to PLACE" >> "$HOME/Documents/vm-sync-to-remote.log"
}

function sync_vm_host2 {
    echo "$(date) - START syncing HOST2 VM to PLACE" >> "$HOME/Documents/vm-sync-to-remote.log"
    for vm in "${vm_ps[@]}";
    do $rsync_cmd $rsync_src_ps/$vm $rsync_dst/$vm-$timestamp;
    done
    echo "$(date) - END syncing HOST2 VM to PLACE" >> "$HOME/Documents/vm-sync-to-remote.log"
}

sync_vm_host1
sync_vm_host2

#!/bin/bash
# sync files between my desktop and laptop via rsync
# edit rsync locations to fit your needs

excludelist="--exclude *.zip --exclude *.tar.gz --exclude *.tar --exclude recruit --exclude openshift --exclude IT_OLD
--exclude My* --exclude *Viber* --exclude *.ISO --exclude *.iso --exclude *.qcow2"
myuser=`whoami`
desktop_loc="XXX.XXX.X.XX:/home/$myuser"
local_loc="/home/$myuser"

sync_from_desktop() {
        rsync -av --progress -e ssh $desktop_loc/Documents/ $local_loc/Documents/ $excludelist
	rsync -av --progress -e ssh $destop_loc/CPC-receipt/ $local_loc/CPC-receipt/ $excludelist
	rsync -av --progress -e ssh $desktop_loc/Pictures/ $local_loc/Pictures/ $excludelist
        rsync -av --progress -e ssh $desktop_loc/scripts/ $local_loc/scripts/ $excludelist
}

sync_to_desktop() {
        rsync -av --progress $local_loc/Documents/ -e ssh $desktop_loc/Documents/ $excludelist
	rsync -av --progress $local_loc/CPC-receipt/ -e ssh $desktop_loc/CPC-receipt/ $excludelist
	rsync -av --progress $local_loc/Pictures/ -e ssh $desktop_loc/Pictures/ $excludelist
        rsync -av --progress $local_loc/scripts/ -e ssh $desktop_loc/scripts/ $excludelist
}

echo "Syncing Data from Desktop.."
sync_from_desktop >/dev/null 2>&1
echo "Syncing Data to Desktop.."
sync_to_desktop >/dev/null 2>&1
echo "Done!"

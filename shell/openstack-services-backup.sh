#!/bin/sh
# script to backup config files, user data, instances etc prior
# to upgrading OpenStack to a new release.
# backup nova, glance, cinder, neutron, keystone configs, database
# requires $myssh key forwarding and keys in place
# requires NFS storage mounted on the host under /mnt/backups/$myhost
# my example utilizes 3-replica Gluster storage for cinder/glance

oslab_nodes=(host07 host08 host09 host10 host11 host12 host13 host14) 
oslab_controller=(host02)
oslab_networker=(host03)
oslab_storage=(host04 host05 host06)
dump_date=$(/bin/date +%Y%m%d%H%M)
mysqldump=`which mysqldump`
mysqldump_opts='--all-databases --opt --single-transaction --master-data --events'
myssh='ssh -n -o StrictHostKeyChecking=false'

#### BEGIN BACKUPS ####

## NOVA ##
oslab_backup_etc_nova() {
   $myssh root@$x "rsync -av --progress /etc/nova /mnt/backups/$x/" 2>&1 >/dev/null 
}

for x in ${oslab_nodes[@]}; do
echo "backing up /etc/nova on $x";
oslab_backup_etc_nova; 
echo "/etc/nova backup complete on $x";
done

oslab_backup_var_lib_nova() {
   $myssh root@$x "rsync -av --progress /var/lib/nova /mnt/backups/$x/" 2>&1 >/dev/null
}

for x in ${oslab_nodes[@]}; do
echo "backing up /var/lib/nova on $x";
oslab_backup_var_lib_nova &
done

## GLANCE ##
oslab_backup_var_lib_glance() {
   $myssh root@$x "rsync -av --progress /srv/gluster/glance /mnt/backups/$x/" 2>&1 >/dev/null
}

for x in ${oslab_storage[0]}; do
echo "backing up /srv/gluster/glance on $x";
oslab_backup_var_lib_glance & 
echo "/srv/gluster/glance backup complete on $x";
done

## CINDER ##
oslab_backup_var_lib_cinder() {
   $myssh root@$x "rsync -av --progress /srv/gluster/cinder /mnt/backups/$x/" 2>&1 >/dev/null
}

for x in ${oslab_storage[0]}; do
echo "backing up /srv/gluster/cinder on $x";
oslab_backup_var_lib_cinder & 
done

## NEUTRON ##
oslab_backup_etc_neutron() {
   $myssh root@$x "rsync -av --progress /etc/neutron /mnt/backups/$x/" 2>&1 >/dev/null
}

for x in ${oslab_networker[@]}; do
echo "backing up /etc/neutron on $x";
oslab_backup_etc_neutron;
echo "/etc/neutron backup complete on $x";
done

## KEYSTONE ##
oslab_backup_etc_keystone() {
   $myssh root@$x "rsync -av --progress /etc/keystone /mnt/backups/$x/" 2>&1 >/dev/null
}

for x in ${oslab_controller[@]}; do
echo "backing up /etc/keystone on $x";
oslab_backup_etc_keystone; 
echo "/etc/keystone backup complete on $x";
done

## DATABASE ##
oslab_backup_mysql() {
   $myssh root@$x "$mysqldump $mysqldump_opts | /usr/bin/gzip - > \
   /mnt/backups/$x/mysqldump-oslab-${dump_date}.gz 2>&1 >/dev/null"
}

#### END BACKUPS ####
#### BEGIN DB BACKUPS ####

for x in ${oslab_controller[@]}; do
echo "backing up MySQL database on $x";
oslab_backup_mysql; 
echo "MySQL backup complete on $x";
done

#### END DB BACKUPS ####

wait
echo "All Backups Complete!"

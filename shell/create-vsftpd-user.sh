#!/bin/bash
# simple interactive script to create a vsftpd user
# this creates a system user then matches that user with htpasswd
# requires: httpd-tools, vsftpd
# assumes: /etc/vsftpd/passwd

echo "=============================="
echo "=      FTP Creator 3000      ="
echo "=============================="
echo "                              "
echo "Enter username:"
echo "                  "

fusername=$(head -n1)

echo "               "
echo "Enter password:"
echo "               "

fpassword=$(head -n1)

create_ftp_user() {
	echo "creating user $fusername"
	adduser -s /sbin/nologin $fusername
	echo "setting password..."
	echo "$fpassword" | passwd $fusername --stdin
	htpasswd -b /etc/vsftpd/passwd $fusername $fpassword
        echo "============================"
        echo "    Account Summary       "
        echo "                              "
        echo "    user: $fusername          "
        echo "    pass: $fpassword          "
        echo "                              "
        echo "============================"
}      

if [ ! -z $fusername ] && [ ! -z $fpassword ];
then
	create_ftp_user
else

        echo "::ERROR:: either username or password is empty"
        exit 1
fi

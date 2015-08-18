#!/bin/sh
# tool to test Horizon login availability
# useful when spinning up many openstack environments at scale to test
# that automated deployments were completed and working

horizonhost=$1
username=$2
password=$3

# print usage if not specified
if [[ $# -eq 0 ]]; then
        echo "USAGE: ./openstack-horizon-login.sh \$HORIZONHOST \$USERNAME \$PASSWORD"
        echo "       ./openstack-horizon-login.sh 10.0.0.1 admin yourpassword"
        echo "                                                              "
        exit 1
fi

url=http://$horizonhost
tmpfile=`mktemp /tmp/horizonXXXXXX`
cookies=`mktemp /tmp/cookiesXXXXXX`
cookies2=`mktemp /tmp/cookies2XXXXXX`
results=`mktemp /tmp/resultsXXXXXX`
postfile=`mktemp /tmp/postfileXXXXXX`

# obtain working copy of site
wget --save-headers --keep-session-cookies --save-cookies=$cookies -q -O - $url > $tmpfile

# munge out OpenStack related fields
region=`grep 'name="region" value=' $tmpfile  | awk -F\" '{ print $6 }' | sed -e 's/:/%3A/g' -e 's,/,%2F,g'`
token=`grep csrfmiddlewaretoken $tmpfile | sed "s/.*value='\(.*\)'.*/\1/g"`

# login and record results
echo "csrfmiddlewaretoken=$token&region=$region&username=$username&password=$password" > $postfile
wget --save-headers -q -O - --load-cookies=$cookies --keep-session-cookies --save-cookies=$cookies2 --post-data="csrfmiddlewaretoken=$token&region=$region&username=$username&password=$password" $url/dashboard/auth/login/ > $results

# cleanup
rm -f $tmpfile $cookies $cookies2 $postfile

# assume "/dashboard/project/" should be in the results, this indicates sucess  
if grep -q "/dashboard/project/" $results ; then
  echo OK Login succeeded
  exitstatus=0
else
  echo CRITICAL Login Failed
  exitstatus=2
fi

# final cleanup and exit
rm -f $results
exit $exitstatus

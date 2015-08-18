#!/bin/sh
# tool to test Horizon login availability
# useful when spinning up many openstack environments at scale to test
# that automated deployments were completed and working

horizonhost=$1
username=$2
password=$3

url=http://$horizonhost

tmpfile=`mktemp /tmp/horizonXXXXXX`
cookies=`mktemp /tmp/cookiesXXXXXX`
cookies2=`mktemp /tmp/cookies2XXXXXX`
results=`mktemp /tmp/resultsXXXXXX`
postfile=`mktemp /tmp/postfileXXXXXX`

wget --save-headers --keep-session-cookies --save-cookies=$cookies -q -O - $url > $tmpfile

region=`grep 'name="region" value=' $tmpfile  | awk -F\" '{ print $6 }' | sed -e 's/:/%3A/g' -e 's,/,%2F,g'`

token=`grep csrfmiddlewaretoken $tmpfile | sed "s/.*value='\(.*\)'.*/\1/g"`

echo "csrfmiddlewaretoken=$token&region=$region&username=$username&password=$password" > $postfile

wget --save-headers -q -O - --load-cookies=$cookies --keep-session-cookies --save-cookies=$cookies2 --post-data="csrfmiddlewaretoken=$token&region=$region&username=$username&password=$password" $url/dashboard/auth/login/ > $results

rm -f $tmpfile $cookies $cookies2 $postfile

# assume "/dashboard/project/" should be in the results.  This indicates a login success
if grep -q "/dashboard/project/" $results ; then
  echo OK Login succeeded
  exitstatus=0
else
  echo CRITICAL Login Failed
  exitstatus=2
fi

rm -f $results
exit $exitstatus

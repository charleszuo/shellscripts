#!/bin/sh

###########################################################################
# shell name for examle /usr/bin/service
#
###########################################################################

PATH=/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin:/home/charles/bin

appname=$1

if [ -z $appname ]; then
	echo "Please input the application name to be killed!"
	exit 0
fi

pids=$(pstree -p | grep -i $appname | egrep -v '.*\|.*(\||`)' | sed -rn 's/.*\(([0-9]+)\).*\([0-9]+\).*/\1/ p')

for pid in $pids
do
	kill -9 $pid
done

exit 0



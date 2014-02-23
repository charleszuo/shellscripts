#!/bin/sh

###########################################################################
# shell name for examle /usr/bin/service
#
###########################################################################

PATH=/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin:/home/charles/bin
export PATH

if [ -z $1 ]; then 
	echo "Parameter does not exist!"
	exit 1
elif [ ! -f $1 ]; then
	echo "File does not exist!"
	exit 2
fi

tmpfile=`mktemp -t tmp.XXX`
sed -e 's/.*\.\s//' $1 | sed '=' | sed 'N;s/\n//' | sed -r 's/[0-9]+/&. /' > $tmpfile
cp $tmpfile $1
rm -f $tmpfile
exit 0

#!/bin/sh

###########################################################################
# shell name: createsh
# use /home/charles/scripts/shtemplate as template when create shell script
###########################################################################

filename=$1

if [ -z "$filename" ]; then
	echo "Please input a shell name!"
	exit 0
fi

cp -i /home/charles/scripts/shtemplate /home/charles/scripts/${filename}
exit 0

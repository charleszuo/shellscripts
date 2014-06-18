#!/bin/sh

SERVER=$1

HOST_LIST="/home/charles/shell/hostlist"

if [ -f $HOST_LIST ]; then
   command=`grep "\b${SERVER}\b$" $HOST_LIST`
   eval "${command}"
fi



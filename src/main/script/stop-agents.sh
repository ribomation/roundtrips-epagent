#!/bin/sh
set -e
#set -x

for pid in `ls ./run/*.pid 2> /dev/null`; do
  kill -KILL `cat $pid`
  rm -f $pid
done

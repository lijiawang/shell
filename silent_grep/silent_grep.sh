#!/bin/bash
#
if [ $# -ne 2 ];
then
    echo "$0 match_test filename"
fi

match_test=$1
filename=$2

grep -q $match_test $filename

if [ $? -eq 0 ];
then
    echo "Then text exists in the file"
else
    echo "Then does not exist in the file"
fi

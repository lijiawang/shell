#!/bin/bash
if [ $# -ne 2 ];
then
    echo "$0 ip_initial ip_end"
fi
ip_initial=$1
ip_end=$2
ip1=`echo $1|cut -f1-3 -d"."`
init=`echo $1|cut -f4 -d"."`
end=`echo $2|cut -f4 -d"."`
while [ $init -le $end ]
do
    for ip in $ip1.$init;
    do
        ping $ip -c 1 &> /dev/null
        if [ $? -eq 0 ]
        then
            echo $ip is alive
        fi
        init=$[$init+1]
    done
done

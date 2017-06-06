#!/bin/bash
for ip in 192.168.23.{1..255};
do
    ping $ip -c 1 &> /dev/null
    if [ $? -eq 0 ]
    then
        echo $ip is alive
    fi
done

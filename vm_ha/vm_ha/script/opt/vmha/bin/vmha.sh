#!/bin/bash
#===============================================================================
#
#          FILE: vmha.sh
#
#         USAGE: ./vmha.sh
#
#   DESCRIPTION: OpenStack VM High Available
#
#       OPTIONS: ---
#  REQUIREMENTS: Share Storage for VM
#          BUGS: ---
#         NOTES: Install in controller Node
#        AUTHOR: Kevin Zhang, zhang.jinnan@99cloud.net
#  ORGANIZATION: 99cloud
#       CREATED: 03/13/2014 15:07:46 CST
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error
#set -x

#set -o xtrace

ScriptVersion="1.0"
VMHA_CONF_PATH=
VMHA_LOG_PATH=

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
cat <<EOT 
Usage :  ${0##/*/} [options] [--] 

  Options: 
  -h|help       Display this message
  -v|version    Display script version
  -c|config     VMHA configuration file
  -l|logfile    Specify the log path of VMHA

EOT
}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hvc:l:" opt
do
  case $opt in

    h|help     )  usage; exit 0   ;;

    v|version  )  echo "$0 -- Version $ScriptVersion"; exit 0   ;;

    c|config  ) VMHA_CONF_PATH=$OPTARG; ;;

    l|logfile ) VMHA_LOG_PATH=$OPTARG; ;;

    \? )  echo -e "\n  Option does not exist : $OPTARG\n"
          usage; exit 1   ;;

  esac    # --- end of case ---
done
shift $(($OPTIND-1))

[[ -n $VMHA_CONF_PATH ]] && source $VMHA_CONF_PATH



export OS_REGION_NAME
export OS_PROJECT_DOMAIN_ID
export OS_USER_DOMAIN_ID
export OS_PROJECT_NAME
export OS_USERNAME
export OS_PASSWORD
export OS_AUTH_URL
export OS_IDENTITY_API_VERSION
export OS_AUTH_VERSION
export OS_COMPUTE_API_VERSION


#defalut parameter

: ${FAILED_CHECK_TIME:=6} #number of ping failed, host-evacuate will occur
: ${PING_INTERVAL:=1} #seconds
: ${PING_TIMEOUT:=2}  #seconds
: ${STONITH_ENABLED:=1}
: ${DEBUG:=0}
: ${VMHA_LOG_PATH:="/opt/vmha/log/vmha.log"}
#: ${TARGET_HOST:="compute3"}
: ${HIGH_AVAILABLE_ZONE:="ha"}
#: ${PRIVATE_KEY:="/opt/vmha/conf/key"}

#eval `ssh-agent -s`
#chmod 400 $PRIVATE_KEY_PATH
#ssh-add $PRIVATE_KEY_PATH


FAILED_HOST_LIST="/opt/vmha/conf/failed_host"

[[ -e $VMHA_LOG_PATH ]]  || { mkdir -p `dirname $VMHA_LOG_PATH`; }

#high available zone list
declare -a HIGH_AVAILABLE_ZONE_LIST=
if [[ -n $HIGH_AVAILABLE_ZONE ]];then
     HIGH_AVAILABLE_ZONE_LIST=(`echo $HIGH_AVAILABLE_ZONE|tr , ' '`)
fi

#filter host list
declare -a VMHA_HOST_FILTER_LIST=
if [[ -n $VMHA_HOST_FILTER ]];then
     VMHA_HOST_FILTER_LIST=(`echo $VMHA_HOST_FILTER|tr , ' '`)
fi


#redirect file descriptor 
if [[ $DEBUG -eq 1 ]]; then
    exec >>$VMHA_LOG_PATH
else
    exec >/dev/null
fi
exec 2>>$VMHA_LOG_PATH


log ()
{
    local msg=$1
    echo `date`" - $msg" >&2
}	# ----------  end of function log  ----------

#return 0 -> host is ping ok
#return 1 -> host ping failed
#return 2 -> host still in failed list

check_host_availiability ()
{
    local host=$1
    for i in `seq $FAILED_CHECK_TIME `; do
        ping -c1 -w$PING_TIMEOUT $host >/dev/null 2>&1
        if [[ $? -eq 0 ]];then
            while read failed_host;do
                if [[ $host == $failed_host ]];then
                    log "$host is recovered. Continue to monitoring."
                    eval sed -i -e '/^$host\$/d' $FAILED_HOST_LIST
                    #to handle the network down, we need to restart nova-compute service 
                    (ssh root@$host "service openstack-nova-compute restart")&
                fi
            done < $FAILED_HOST_LIST
            return 0
        fi
        while read failed_host;do
            if [[ $host == $failed_host ]];then
                return 2
            fi
        done < $FAILED_HOST_LIST
        echo -e "ping host $host failed $i time"
        sleep $PING_INTERVAL
    done
    return 1
}	# ----------  end of function check_host_availiability  ----------



#return : 0-> nova service is OK
#return : 1-> nova service failed

check_nova_compute_status ()
{
    local host=$1
    host_state=$(nova-manage service list|awk -v host=$host '{if($1=="nova-compute" && $2==host){print $5}}')
    if [[ $host_state == ':-)' ]];then
        return 0
    elif [[ $host_state == 'XXX' ]];then
        return 1
    fi
    return 0
}	# ----------  end of function check_nova_compute_status  ----------


#migrate fail host
host_evacuate ()
{
   if [[ -z $1 ]];then
        return 1
   fi
   host=$1
   log "Excuting host evacuate on host $host"
   nova host-evacuate $host  --on-shared-storage
   #sleep 6
   #while read line ;do
   #    nova start $line
   #done < <(nova list --host $TARGET_HOST|awk -F'|' '{print $3,$4}'|awk '{if($2=="SHUTOFF"){print $1}}')
}	# ----------  end of function host_evacuate  ----------





# main here
while true; do
    for zone in ${HIGH_AVAILABLE_ZONE_LIST[@]};do
        declare -a NOVA_HOST=()
        [[  -e $FAILED_HOST_LIST ]] || { mkdir -p `dirname $FAILED_HOST_LIST`;touch $FAILED_HOST_LIST; }
#        NOVA_HOST=$(nova service-list |awk -F'|' "/$zone/"'{if($3 ~ "nova-compute" && $5 ~ '" $zone "'){print $4}}')
NOVA_HOST=$(nova service-list |awk -F'|' "/$zone/"'{if($3 ~ "nova-compute" && $6 ~ "enabled" && $5 ~ '" $zone "'){print $4}}')
# | while read line; 
while false;
        do
            for filter_host in ${VMHA_HOST_FILTER_LIST[@]};do
                [[ $filter_host == $line ]] && { echo -e "$filter_host is filterd";continue 2; }
            done
            NOVA_HOST=(${NOVA_HOST[@]} $line)
        done 

        for host in ${NOVA_HOST[@]}; do
            echo -e $host
            echo hello $host
            (
            check_host_availiability $host
            if [[ $? -eq 1 ]];then
                echo -e " in failed logical"
                check_nova_compute_status $host
                if [[ $? -eq 1 ]] ; then 
                    echo $host >> $FAILED_HOST_LIST
                    log "host $host in $zone available zone is down. Executing the HA."
                    host_evacuate $host
                fi
            fi
            )&
        done
    done
    wait
    echo -e "one cycle done"
    sleep 2
done

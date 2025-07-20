#!/bin/sh

#------------------------------------------------------------------
# © 2013 Belkin International, Inc. and/or its affiliates. All rights reserved.
#------------------------------------------------------------------

#------------------------------------------------------------------
#             service_belkin_icc.sh
#------------------------------------------------------------------

source /etc/init.d/ulog_functions.sh
source /etc/init.d/event_handler_functions.sh

#------------------------------------------------------------------
# name of this service
# This name MUST correspond to the registration of this service.
# Usually the registration occurs in /etc/registration.
# The registration code will refer to the path/name of this handler
# to be activated upon default events (and other events)
#------------------------------------------------------------------
SERVICE_NAME="belkin_icc"

CRON_TAB_FILE="/tmp/cron/cron.everyminute/belkin_icc_everyminute.sh"

PING_LOCATION="heartbeat.belkin.com"
DNS1_LOCATION="www.belkin.com"
DNS2_LOCATION="a.root-servers.net"
SYSEVENT_NAME="icc_internet_state"

LOCK_FILE="/tmp/service_belkin_icc.lock"

# -----------------------------------------------------------------------------
# try lock (non blocking)
# -----------------------------------------------------------------------------
try_lock()
{
    local try_again="1"

    while [ "$try_again" = "1" ]; do
        ( set -o noclobber; echo "$$" > $LOCK_FILE ) 2> /dev/null
        if [ "$?" = "0" ]; then
            trap 'rm -f $LOCK_FILE; exit $?' INT TERM EXIT
            return 0
        fi

        # check /proc to see if process still exists
        local pid=`cat $LOCK_FILE`
        if [ ! -d "/proc/$pid" ]; then
            rm -rf $LOCK_FILE
        else
            try_again="0"
        fi
    done

    return 1
}

# -----------------------------------------------------------------------------
# lock (blocking)
# -----------------------------------------------------------------------------
lock()
{
    local has_lock="0"

    while [ "$has_lock" = "0" ]; do
        try_lock
        if [ "$?" = "0" ]; then
            has_lock="1"
        fi
        sleep 1
    done
}

# -----------------------------------------------------------------------------
# unlock
# -----------------------------------------------------------------------------
unlock()
{
    rm -rf $LOCK_FILE
    trap - INT TERM EXIT
}

# -----------------------------------------------------------------------------
# set sysevent internet up
# -----------------------------------------------------------------------------
set_sysevent_internet_up()
{
    local state=`sysevent get $SYSEVENT_NAME`

    if [ "$state" != "up" ]; then
        sysevent set $SYSEVENT_NAME up
    fi
}

# -----------------------------------------------------------------------------
# set sysevent internet down
# -----------------------------------------------------------------------------
set_sysevent_internet_down()
{
    local state=`sysevent get $SYSEVENT_NAME`

    if [ "$state" != "down" ]; then
        sysevent set $SYSEVENT_NAME down
    fi
}

# -----------------------------------------------------------------------------
# handle ping
# The -w option may not be enough because that's only the ping timeout. If DNS
# resolution takes a long time, it'll just block until DNS times out. We
# need drop dead time at 5 seconds
#
# returns 0 - success
# returns 1 - failed
# -----------------------------------------------------------------------------
do_ping()
{
    # run ping in child process
    #( ping -q -c1 -w5 $PING_LOCATION &> /dev/null ) &
    ( ping -q -c1 -w2 $PING_LOCATION &> /dev/null ) &
    local pid=$!

    # wait
    sleep 3

    # if child process is still there, then kill it
    if [ -d "/proc/$pid" ]; then
        ( kill -9 $pid ) 2> /dev/null
    fi

    # check result
    wait $pid
    return $?
}

# -----------------------------------------------------------------------------
# handle nslookup
# the busybox version of nslookup doesn't support options, so we force
# kill it once the timeout expires
#
# INPUT
# $1 - host name to lookup
# RETURN
# 0 - success
# 1 - fail
# -----------------------------------------------------------------------------
do_nslookup()
{
    # run nslookup in child process
    ( nslookup "$1" &> /dev/null ) &
    local pid=$!

    # wait
    sleep 5

    # if child process is still there, then kill it
    if [ -d "/proc/$pid" ]; then
        ( kill -9 $pid ) 2> /dev/null
    fi

    # check result
    wait $pid

    return $?
}

# -----------------------------------------------------------------------------
# do the DNS queries, does not set sysevent
#
# success - return 0
# fail - return 1
# -----------------------------------------------------------------------------
do_dns_queries()
{
    do_nslookup "$DNS1_LOCATION"
    if [ "$?" = "0" ]; then
        return 0
    fi

    do_nslookup "$DNS1_LOCATION"
    if [ "$?" = "0" ]; then
        return 0
    fi

    do_nslookup "$DNS2_LOCATION"
    if [ "$?" = "0" ]; then
        return 0
    fi

    do_nslookup "$DNS2_LOCATION"
    if [ "$?" = "0" ]; then
        return 0
    fi

    return 1
}

# -----------------------------------------------------------------------------
# checks if WAN IP is a private IP addr, i.e. 192.168.x.x/10.x.x.x
# return 0 = yes
# return 1 = no
# -----------------------------------------------------------------------------
is_wan_ip_private()
{
    local ip=`sysevent get ipv4_wan_ipaddr`

    expr match "$ip" "192.168." > /dev/null
    if [ "$?" = "0" ]; then
        return 0
    fi

    expr match "$ip" "10." > /dev/null
    if [ "$?" = "0" ]; then
        return 0
    fi

    return 1
}

# TODO not yet completed, but since we're not implementing the NAT
# incoming packet check, this is left unfinished.
# -----------------------------------------------------------------------------
# retrieves the last wan2lan pkt count
# OUTPUT
# sets PKT_COUNT
# -----------------------------------------------------------------------------
#get_last_wan2lan_pkt_count()
#{
#}

# -----------------------------------------------------------------------------
# retrieves NAT incoming WAN 2 LAN packet count
# OUTPUT
# sets PKT_COUNT
# -----------------------------------------------------------------------------
get_nat_wan2lan_pkt_count()
{
    PKT_COUNT=`iptables -L FORWARD -vx | grep -e " wan2lan" | awk '{print $1}'`
}

# -----------------------------------------------------------------------------
# checks if we've had incoming NAT packet
#
# yes - return 0
# no - return 1
# -----------------------------------------------------------------------------
has_incoming_nat_traffic()
{
    get_last_wan2lan_pkt_count
    local last_count=$PKT_COUNT

    get_net_wan2lan_pkt_count
    local count=$PKT_COUNT

    if [ "$count" -gt "$last_count" ]; then
        return 0
    fi

    return 1
}

# -----------------------------------------------------------------------------
# Performs the ping test, sets proper sysevent
#
# success - return 0
# fail - return 1, if the link is down and there's no reason to keep running
#                  this test
# -----------------------------------------------------------------------------
run_ping_test()
{
    do_ping
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    local sysevent_set=0
    local link
    local i

    while true; do
        # We loop a bunch of ping tests before we check WAN proto again.
        # This way worst case, we'll do a number of pointless pings, then stop
        # as opposed to polling syseventd for wan-status every 5 seconds
        # everytime
        for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
            do_ping
            if [ "$?" = "0" ]; then
                set_sysevent_internet_up
                return 0
            fi

            if [ "$sysevent_set" = "0" ]; then
                set_sysevent_internet_down
                sysevent_set=1
            fi
        done

        # if WAN proto is not up, there's no point running this test
        wan_status=`sysevent get wan-status`
        if [ "$wan_status" != "started" ]; then
            set_sysevent_internet_down
            return 1
        fi
    done
}

run_cbt_ping_test()
{
    do_ping
    #PHY=`ssdk_sh port linkstatus get 5 |grep SSDK |(sed -n 's/.*'Status]:'/ /p')`
    #if [ $PHY == "ENABLE" ]; then
       if [ "$?" = "0" ]; then
           #set_sysevent_internet_up
	   echo none > /sys/class/leds/internet/trigger
       else	
           #set_sysevent_internet_down
           echo default-on > /sys/class/leds/internet/trigger
       fi
    #fi
}

# -----------------------------------------------------------------------------
# Performs DNS-only test, sets proper sysevent
#
# success - return 0
# fail - return 1
# -----------------------------------------------------------------------------
run_dns_test()
{
    do_dns_queries
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    # failed, set down state
    set_sysevent_internet_down

    # try again
    do_dns_queries
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    # already down, no need to set it again
    return 1
}

# -----------------------------------------------------------------------------
# performs incoming NAT test + DNS test, sets proper sysevent
#
# success - return 0
# fail - return 1
# -----------------------------------------------------------------------------
run_nat_plus_dns_test()
{
    has_incoming_nat_traffic
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    do_dns_queries
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    has_incoming_nat_traffic
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    set_sysevent_internet_down

    do_dns_queries
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    has_incoming_nat_traffic
    if [ "$?" = "0" ]; then
        set_sysevent_internet_up
        return 0
    fi

    # already down, no need to set it again
    return 1
}

#------------------------------------------------------------------
# Check for internet connection
# INPUT
# $1 - current wan-status
#------------------------------------------------------------------
belkin_icc_check()
{
    try_lock
    if [ "$?" != "0" ]; then
        # don't do anything if there's already another process
        # running
        return
    fi

    # if WAN proto is not up, do nothing
    if [ "$1" != "started" ]; then
        set_sysevent_internet_down
        unlock
        exit
    fi

    internet=`sysevent get $SYSEVENT_NAME`
    if [ "$internet" != "up" ]; then
        # ping until we get internet, or WAN proto goes down
        run_ping_test
    else
        # internet is already up, do DNS check
        run_dns_test
        if [ "$?" != "0" ]; then
            # DNS check failed, go back to ping test
            run_ping_test
        fi
    fi

    unlock
}

#------------------------------------------------------------------
# Check if Belkin ICC should be enabled
#------------------------------------------------------------------
check_belkin_icc_enable()
{
    # check if Belkin ICC should be active
    local enabled=`syscfg get belkin_icc_enabled`
    if [ "$enabled" != "1" ]; then
        service_stop
        exit 0
    fi

    # Belkin ICC is diabled for bridge mode as well
    bridge_mode=`syscfg get bridge_mode`
    if [ "$bridge_mode" != "0" ]; then
        service_stop
        exit 0
    fi
}

#------------------------------------------------------------------
# create Cron job
#------------------------------------------------------------------
create_cron_file ()
{
(
cat <<'End-of-Text'
#!/bin/sh
/etc/init.d/service_belkin_icc.sh cron &
End-of-Text
) > $CRON_TAB_FILE
    echo "Belkin ICC Cron job created" > /dev/console
    return 0
}

#------------------------------------------------------------------
#  function   : service_start
#  - Set service-status to starting
#  - Add code to read normalized configuration data from syscfg and/or sysevent 
#  - Create configuration files for the service
#  - Start any service processes 
#  - Set service-status to started
#
#  check_err will check for a non zero return code of the last called function
#  set the service-status to error, and set the service-errinfo, and then exit
#------------------------------------------------------------------
service_start ()
{
    # wait_till_end_state will wait a reasonable amount of time waiting for ${SERVICE_NAME}
    # to finish transitional states (stopping | starting)
    wait_till_end_state ${SERVICE_NAME}

    STATUS=`sysevent get ${SERVICE_NAME}-status`
    if [ "started" != "$STATUS" ] ; then
        sysevent set ${SERVICE_NAME}-errinfo 
        sysevent set ${SERVICE_NAME}-status starting
        create_cron_file
        chmod +x $CRON_TAB_FILE
        check_err $? "Couldnt handle start"
        sysevent set ${SERVICE_NAME}-status started
    fi
}

#------------------------------------------------------------------
#  function   : service_stop
#  - Set service-status to stopping
#  - Stop any service processes 
#  - Delete configuration files for the service
#  - Set service-status to stopped
#
#  check_err will check for a non zero return code of the last called function
#  set the service-status to error, and set the service-errinfo, and then exit
#------------------------------------------------------------------
service_stop ()
{
    # wait_till_end_state will wait a reasonable amount of time waiting for ${SERVICE_NAME}
    # to finish transitional states (stopping | starting)
    wait_till_end_state ${SERVICE_NAME}

    STATUS=`sysevent get ${SERVICE_NAME}-status`
    if [ "stopped" != "$STATUS" ] ; then
        sysevent set ${SERVICE_NAME}-errinfo 
        sysevent set ${SERVICE_NAME}-status stopping
        rm -rf $CRON_TAB_FILE
        check_err $? "Couldnt handle stop"
        sysevent set ${SERVICE_NAME}-status stopped
    fi

    set_sysevent_internet_down
}


#----------------------------------------
#cbt check
#---------------------------------------
bring_up_icc_mechanism ()
{
    #wait for DNS ready 	
    sleep 20; 	

    while : 
    do
    #PHY=`ssdk_sh port linkstatus get 5 |grep SSDK |(sed -n 's/.*'Status]:'/ /p')`
    #if [ $PHY == "DISABLE" ]; then
	#   echo none > /sys/class/leds/internet/trigger
	#    exit
    #fi
    wan_status=`sysevent get wan-status`
    if [ "$wan_status" != "started" ];then
        echo default-on > /sys/class/leds/internet/trigger
        exit
    fi
	run_cbt_ping_test
	sleep 10;
    done
}


#------------------------------------------------------------------
# Entry
# The first parameter $1 is the name of the event that caused this handler to be activated
# The second parameter $2 is the value of the event or "NULL" if there is no value
# The other parameters are given if parameters passing was defined in the sysevent async call
#------------------------------------------------------------------
case "$1" in
    ${SERVICE_NAME}-start)
        check_belkin_icc_enable
        service_start
        ;;
    ${SERVICE_NAME}-stop)
        check_belkin_icc_enable
        service_stop
        ;;
    ${SERVICE_NAME}-restart)
        check_belkin_icc_enable
        service_stop
        service_start
        ;;
    cron)
        check_belkin_icc_enable
        wan_status=`sysevent get wan-status`
        belkin_icc_check "$wan_status"
        ;;
    cbt_check)
	bring_up_icc_mechanism
        ;;
    wan-status)
        check_belkin_icc_enable
        if [ "$2" == "started" ]; then
            service_start
            belkin_icc_check "$2"
        else
            service_stop
        fi
        ;;
    *)
        echo "Err: $1" > /dev/console
        echo "Usage: $SERVICE_NAME [ ${SERVICE_NAME}-start | ${SERVICE_NAME}-stop | ${SERVICE_NAME}-restart] | cron | wan-status <wan-status>" > /dev/console
        exit 3
        ;;
esac


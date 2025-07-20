#!/bin/sh
source /etc/init.d/ulog_functions.sh
source /etc/init.d/event_handler_functions.sh
SERVICE_NAME="link_aggregation"
PID_FILE=/var/run/${SERVICE_NAME}.pid
service_start ()
{
	if [ "`syscfg get link_aggregation::enabled`" = "1" ] ; then
		cnt=`syscfg get link_aggregation::port_count`
		port1=0
		port2=0
		port3=0
		port4=0
		nv_prefix="syscfg get link_aggregation::port"
		for i in `seq 1 $cnt`
		do
			val=`$nv_prefix$i`
			if [ ! -z "$val" ]; then
				case $val in
					0)
						port1=$((1<<1))
						;;
					1)
						port2=$((1<<2))
						;;
					2)
						port3=$((1<<3))
						;;
					3)
						port4=$((1<<4))
						;;
					 *)
				esac
			fi
		done
                ssdk_sh trunk group set 0 enable 0x$((port1 | port2 |port3 |port4))
		sysevent set ${SERVICE_NAME}-status started
	else
                ssdk_sh trunk group set 0 disable 0
		sysevent set ${SERVICE_NAME}-status stopped
	fi
}
service_stop ()
{
	ssdk_sh debug reg set 0x270 0xF 4
	ssdk_sh trunk group set 0 disable 0
	sysevent set ${SERVICE_NAME}-status stopped
}
service_restart ()
{
    service_start
}
case "$1" in
    ${SERVICE_NAME}-start)
        service_start
        ;;
    ${SERVICE_NAME}-stop)
        service_stop
        ;;
    ${SERVICE_NAME}-restart)
        service_restart
        ;;
    link_aggregation_changed)
        service_restart
        ;;
    lan-status)
        LAN_STATUS=`sysevent get lan-status`
        if [ "started" == "${LAN_STATUS}" ] ; then
            service_start
        elif [ "stopped" == "${LAN_STATUS}" ] ; then
            service_stop
        fi
        ;;
    *)
        echo "Usage: $SERVICE_NAME [ ${SERVICE_NAME}-start | ${SERVICE_NAME}-stop | ${SERVICE_NAME}-restart ]" >&2
        exit 3
        ;;
esac

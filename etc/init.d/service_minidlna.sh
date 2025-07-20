#!/bin/sh
source /etc/init.d/ulog_functions.sh
source /etc/init.d/event_handler_functions.sh
SERVICE_NAME="mediaserver"
CFGDIR="/tmp/config"
CFGFILE="$CFGDIR/minidlna.conf"
LOG_FILE="/tmp/minidlna_log.txt"
echo "" > $LOG_FILE
dfc_enabled="0"
service_init ()
{
	echo "$SERVICE_NAME service_init"
	supp="`syscfg get MediaServer::mediaServerSupport`"
	if [ "$supp" == "0" ] ; then
		echo "$SERVICE_NAME not support" >> /dev/console
		exit 1
	fi
	ena="`syscfg get MediaServer::mediaServerEnable`"
	if [ "$ena" == "1" ] ; then
		echo "$SERVICE_NAME running $1" >> /dev/console
	else
		echo "$SERVICE_NAME not enabled in syscfg" >> /dev/console
		exit 1
	fi
	if [ ! -d "$CFGDIR" ]; then
		mkdir -p "$CFGDIR"
	fi
}
get_first_media_drive () {
  drive=`ls /mnt/ | grep sd | sort | head -n 1`
  if [ "$drive" ] ; then
    echo "$drive"
  fi
}
service_start ()
{
  wait_till_end_state ${SERVICE_NAME}
  drive_count=`sysevent get no_usb_drives`
  if [ "$drive_count" == "" ] || [ "$drive_count" == "0" ] ; then
	echo "no storage drive attached" >> $LOG_FILE
	return
  else
  config_cgroup
  wait_till_end_state usb_mountscript
  wait_till_end_state vsftpd
  name_server="`syscfg get MediaServer::name`"
  if [ "$name_server" == "" ] ; then
	name_server=`hostname`
  fi
  minidlna_port="`syscfg get MediaServer::port`"
  if [ "$minidlna_port" == "" ] ; then
	minidlna_port=9999
  fi
  if [ "`sysevent get ${SERVICE_NAME}-delay_start`" == "" ] ; then
		sleep 15
		sysevent set ${SERVICE_NAME}-delay_start done
  fi
	service_init
	STATUS=`sysevent get ${SERVICE_NAME}-status`
	if [ "started" != "$STATUS" ] ; then
		sysevent set ${SERVICE_NAME}-errinfo 
		sysevent set ${SERVICE_NAME}-status starting
        med_folder_count=`syscfg get MedFolderCount`
        if [ "$med_folder_count" == "" ] || [ "$med_folder_count" == "0" ] ; then
	    DEVS=`ls /dev/ | grep -r "sd[a-z]" | uniq`
	    contentdir=""
	    if [ "$DEVS" != "" ] ; then
	        	for d in $DEVS
	        	do
				if [ -d "/mnt/$d" ] ; then
	        			contentdir="media_dir=AVP,/mnt/$d \n$contentdir"
	        		fi
	        	done
	    fi
        else
            drive=""
            folder=""
            for num in `seq 1 $med_folder_count`
            do
            drive=`syscfg get med_$num::drive`
            folder=`syscfg get med_$num::folder`
               if [ -d "/mnt/$drive$folder" ] ; then
                  contentdir="media_dir=AVP,/mnt/$drive$folder \n$contentdir"
               fi
            done
        fi
		echo "Starting ${SERVICE_NAME}"
		cp /etc/minidlna.conf $CFGFILE
  		DEFDRIVE=$(get_first_media_drive)
		db_dir="/mnt/$DEFDRIVE/.dlna/"
		sed -i '/friendly_name=/c\friendly_name=' $CFGFILE
		sed -i "s%friendly_name=%friendly_name=$name_server%g" $CFGFILE
		sed -i '/port=/c\port=' $CFGFILE
		sed -i "s%port=%port=$minidlna_port%g" $CFGFILE
		sed -i "s|media_dir=|$contentdir|" $CFGFILE
		sed -i '/db_dir=/c\db_dir=' $CFGFILE
		sed -i "s%db_dir=%db_dir=$db_dir%g" $CFGFILE
		/sbin/minidlnad -R -f $CFGFILE &
		check_err $? "Couldnt handle start"
		sysevent set ${SERVICE_NAME}-status started
	fi
  fi
}
service_stop ()
{
   wait_till_end_state ${SERVICE_NAME}
   STATUS=`sysevent get ${SERVICE_NAME}-status`
   if [ "stopped" != "$STATUS" ] ; then
      sysevent set ${SERVICE_NAME}-errinfo 
      sysevent set ${SERVICE_NAME}-status stopping
      MINIDLNA_PID="`cat /var/run/minidlna/minidlna.pid`"
      kill -INT $MINIDLNA_PID 
      check_err $? "Couldnt handle stop"
      sysevent set ${SERVICE_NAME}-status stopped
   fi
}
service_restart()
{
   service_stop
   sleep 3
   service_start
}
config_cgroup()
{
   if [ ! -f /cgroup/tasks ] ; then
      return
   fi
   if [ ! -d /cgroup/minidlna ] ; then
      mkdir -p /cgroup/minidlna
      echo 3 > /proc/sys/vm/drop_caches
      local mem
      mem=`grep -e '^MemTotal' /proc/meminfo | awk '{print $2}'` 
      mem=`expr $mem / 4`
      local free
      free=`grep -e '^MemFree' /proc/meminfo | awk '{print $2}'` 
      free=`expr $free - 10240`
      if [ "$mem" -gt "$free" ] ; then
         mem=$free
      fi
      mem=`expr $mem \* 1024`
      echo "$mem" > /cgroup/minidlna/memory.limit_in_bytes
      echo 1 > /cgroup/minidlna/memory.oom_control
   fi
   echo 0 > /cgroup/minidlna/tasks
}
wait_eth_power_cycle ()
{
	local retry=0
	while [ $retry -lt 30 ] ; do
		laststatus=`sysevent get eth-status`
		if [ "$laststatus" != "power-cycled" ] ; then
			sleep 1
			retry=`expr $retry + 1`
			echo "wait_eth_power_cycle: $retry" > /dev/console
		else
			return
		fi
	done
}
cleanup_eth_power_cycle ()
{
	sysevent set eth-status
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
   no_usb_drives)
      echo "minidlna detect no_usb_drives change" >> /dev/console
      service_restart
      ;;
   dns-restart)
      echo "minidlna restart from dns restart" >> /dev/console
      wait_eth_power_cycle
      service_restart
      cleanup_eth_power_cycle
      ;;
   hostname_changed)
      echo "minidlna restart from hostname change" >> /dev/console
      service_restart
      ;;
   *)
      echo "Usage: $SERVICE_NAME [ ${SERVICE_NAME}-start | ${SERVICE_NAME}-stop | ${SERVICE_NAME}-restart]" > /dev/console
      exit 3
      ;;
esac

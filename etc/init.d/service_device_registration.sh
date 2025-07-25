#!/bin/sh
source /etc/init.d/ulog_functions.sh
source /etc/init.d/event_handler_functions.sh
SERVICE_NAME="device_registration"
SELF_NAME="`basename $0`" 
LOCKFILE="/tmp/${SERVICE_NAME}.lock"
TOKEN_REFRESH_INTERVAL=daily
TOKEN_REFRESH_CRONFILE="/etc/cron/cron.${TOKEN_REFRESH_INTERVAL}/refresh_token.sh"
PID_FILE="/tmp/var/run/${SERVICE_NAME}.pid"
REG_SCRIPT="/usr/local/lib/lua/5.1/device_registration.lua"
log_it() 
{
   ulog $SERVICE_NAME "$1" "$2"
   echo "$SERVICE_NAME: $2" >>/dev/console
}
create_cron_job()
{
   cat > $TOKEN_REFRESH_CRONFILE << EOF
#!/bin/sh
sysevent set refresh_token
EOF
   chmod 700 $TOKEN_REFRESH_CRONFILE
}
stop_registration()
{
   if [ -f $PID_FILE ]; then
      kill -9 $(cat $PID_FILE) > /dev/null 2>&1
      rm -f $PID_FILE
   fi
}
service_start() 
{
   wait_till_end_state ${SERVICE_NAME}
   if [ "$(sysevent get ${SERVICE_NAME}-status)" == "started" ]; then
      return
   fi
   sysevent set ${SERVICE_NAME}-status "starting"
   sysevent set ${SERVICE_NAME}-errinfo
   if [ -z "$(syscfg get device::linksys_token)" ]; then
      ${REG_SCRIPT} register &
      echo $! > $PID_FILE
   else
      create_cron_job
   fi
   sysevent set ${SERVICE_NAME}-status "started"
   log_it status "Service started"
}
service_stop() 
{
   wait_till_end_state ${SERVICE_NAME}
   if [ "$(sysevent get ${SERVICE_NAME}-status)" == "stopped" ]; then
      return
   fi
   sysevent set ${SERVICE_NAME}-status "stopping"
   stop_registration
   rm -f $TOKEN_REFRESH_CRONFILE > /dev/null 2>&1
   sysevent set ${SERVICE_NAME}-errinfo
   sysevent set ${SERVICE_NAME}-status "stopped"
   log_it status "Service stopped" 
}
lock $LOCKFILE
log_it status "Received event: $1"
case "$1" in
   ${SERVICE_NAME}-start)
      service_start
      ;;
   ${SERVICE_NAME}-stop)
      service_stop
      ;;
   ${SERVICE_NAME}-restart)
      service_stop
      service_start
      ;;
   wan-started)
      service_start
      ;;
   wan-stopped)
      service_stop
      ;;
   device_registered)
      stop_registration
      create_cron_job
      ;;
   refresh_token)
      ${REG_SCRIPT} renew
      ;;
   *)
      echo "Usage: $SELF_NAME [${SERVICE_NAME}-start|${SERVICE_NAME}-stop|${SERVICE_NAME}-restart|wan-started|wan-stopped|refresh_token|device_registered]" >&2
      unlock $LOCKFILE
      exit 3
      ;;
esac
unlock $LOCKFILE

#!/bin/sh
source /etc/init.d/ulog_functions.sh
source /etc/init.d/event_handler_functions.sh
source /etc/init.d/syscfg_api.sh
source /etc/init.d/service_wifi/wifi_utils.sh
source /etc/init.d/service_wifi/wifi_physical.sh
source /etc/init.d/service_wifi/wifi_virtual.sh
source /etc/init.d/service_wifi/wifi_guest.sh
WIFI_DEBUG_SETTING=`syscfg_get ${SERVICE_NAME}_debug`
DEBUG() 
{
    [ "$WIFI_DEBUG_SETTING" = "1" ] && $@
}
DEBUG set -x
LOCK_FILE=/tmp/${SERVICE_NAME}.lock
lock $LOCK_FILE
echo "${SERVICE_NAME}, sysevent received: $1 (`date`)"
STA_PHY_IF=""
service_init()
{
	ulog wlan status "${SERVICE_NAME}, service_init()"
	SYSCFG_FAILED='false'
	FOO=`utctx_cmd get device::deviceType wl_wmm_support lan_wl_physical_ifnames wl0_ssid wl1_ssid lan_ifname guest_enabled guest_lan_ifname guest_wifi_phy_ifname wl0_guest_vap guest_ssid_suffix guest_ssid guest_ssid_broadcast guest_lan_ipaddr guest_lan_netmask wl0_state guest_vlan_id backhaul_ifname_list extender_radio_mode`
	eval $FOO
	if [ $SYSCFG_FAILED = 'true' ] ; then
		ulog wlan status "$PID utctx failed to get some configuration data required by service-forwarding"
		ulog wlan status "$PID THE SYSTEM IS NOT SANE"
		echo "${SERVICE_NAME}, [utopia] utctx failed to get some configuration data required by service-system" > /dev/console
		echo "${SERVICE_NAME}, [utopia] THE SYSTEM IS NOT SANE" > /dev/console
		sysevent set ${SERVICE_NAME}-status error
		sysevent set ${SERVICE_NAME}-errinfo "Unable to get crucial information from syscfg"
		exit
	fi
	RECONFIGURE="false"
	STA_PHY_IF=`syscfg_get wifi_sta_phy_if`
	return 0
}
service_start()
{
	ulog wlan status "${SERVICE_NAME}, service_start()"
	STATUS=`sysevent get ${SERVICE_NAME}-status`
	if [ "started" = "$STATUS" ] || [ "starting" = "$STATUS" ]; then
		echo "${SERVICE_NAME} is starting/started, ignore the request"
		ulog wlan status "${SERVICE_NAME} is starting/started, ignore the request"
		return 1
	fi
	if [ "0" = "`syscfg_get bridge_mode`" ] && [ "started" != "`sysevent get lan-status`" ] ; then
		ulog wlan status "${SERVICE_NAME}, LAN is not started,ignore the request"
		return 1
	fi
	echo "${SERVICE_NAME}, service_start()"
	sysevent set ${SERVICE_NAME}-status starting
	wifi_onetime_setting
	if [ -f /etc/init.d/service_wifi/wifi_button.sh ]; then
		/etc/init.d/service_wifi/wifi_button.sh
	fi
	for PHY_IF in $PHYSICAL_IF_LIST; do
		wifi_physical_start $PHY_IF
		wifi_virtual_start $PHY_IF
	done
	start_hostapd
	if [ "`syscfg_get wl_wmm_support`" = "enabled" ] && [ "`syscfg_get wl0_network_mode`" = "11b" ]; then
        	VAP_IF=`syscfg_get wl0_physical_ifname`
        	iwpriv $VAP_IF setwmmparams 1 0 1 4
        	iwpriv $VAP_IF setwmmparams 1 1 1 4
        	iwpriv $VAP_IF setwmmparams 1 2 1 3
        	iwpriv $VAP_IF setwmmparams 1 3 1 2
        	iwpriv $VAP_IF setwmmparams 2 0 1 10
        	iwpriv $VAP_IF setwmmparams 2 1 1 10
        	iwpriv $VAP_IF setwmmparams 2 2 1 4
        	iwpriv $VAP_IF setwmmparams 2 3 1 3
	fi
	if [ "0" != "`syscfg get bridge_mode`" ] && [ -f /etc/init.d/service_wifi/wifi_repeater.sh ] && [ "2" = "`syscfg_get wifi_bridge::mode`" ]; then
		echo "service_wifi service_start, repeater mode enabled"
		/etc/init.d/service_wifi/wifi_repeater.sh
	fi
	if [ "0" != "`syscfg get bridge_mode`" ] && [ -f /etc/init.d/service_wifi/wifi_sta_setup.sh ] && [ "1" = "`syscfg get wifi_bridge::mode`" ]; then
		/etc/init.d/service_wifi/wifi_sta_setup.sh
		source /etc/init.d/service_wifi/wifi_utils.sh
	fi
	update_wifi_cache "physical"
	update_wifi_cache "virtual"
	update_wifi_cache "guest"
	start_lbd
	sysevent set ${SERVICE_NAME}-status started
	return 0
}
service_stop()
{
	ulog wlan status "${SERVICE_NAME}, service_stop()"
	STATUS=`sysevent get ${SERVICE_NAME}-status`
	if [ "stopped" = "$STATUS" ] || [ "stopping" = "$STATUS" ] || [ -z "$STATUS" ]; then
		echo "${SERVICE_NAME} is stopping/stopped, ignore the request"
		ulog wlan status "${SERVICE_NAME} is stopping/stopped, ignore the request"
		return 1
	fi
	
	echo "${SERVICE_NAME}, service_stop()"
	sysevent set ${SERVICE_NAME}-status stopping
	for PHY_IF in $PHYSICAL_IF_LIST; do
		wifi_guest_stop $PHY_IF
		wifi_virtual_stop $PHY_IF
		stop_hostapd $PHY_IF
		wifi_physical_stop $PHY_IF
	done
	stop_lbd
	sysevent set ${SERVICE_NAME}-status stopped
	return 0
}
service_restart()
{
	ulog wlan status "${SERVICE_NAME}, service_restart()"
	service_stop
	service_start
}
wifi_onetime_setting()
{
	ONE_TIME=`sysevent get wifi-onetime-setting`
	if [ "$ONE_TIME" != "TRUE" ] ; then
		ulog wlan status "${SERVICE_NAME}, wifi_onetime_setting()"
		sysevent set wifi-onetime-setting "TRUE"
		sysevent set wl0_status "down"
		sysevent set wl0_guest_status "down"
		sysevent set wl0_tc_status "down"
		sysevent set wl1_status "down"
		sysevent set wl1_guest_status "down"
		sysevent set wl1_tc_status "down"
		sysevent set wl2_guest_status "down"	
		if [ "`cat /etc/product`" = "dallas" ] || [ "`cat /etc/product`" = "xtrail" ]; then
			sysevent set wl2_status "down"
		fi
		load_wifi_driver            
		/etc/init.d/service_wifi/WiFi_info_set.sh &	
		create_files	
		bandsteering_auto_setting
	fi
	return 0
}
wifi_config_changed_handler()
{
	ulog wlan status "${SERVICE_NAME}, wifi_config_changed_handler()"
	echo "${SERVICE_NAME}, wifi_config_changed_handler()"
	
	if [ -f /etc/init.d/service_wifi/wifi_button.sh ]; then
		/etc/init.d/service_wifi/wifi_button.sh
	fi
	if [ "0" = "`syscfg_get bridge_mode`" ] && [ "started" != "`sysevent get lan-status`" ] ; then
		ulog wlan status "${SERVICE_NAME}, LAN is not started,ignore the request"
		echo "${SERVICE_NAME}, LAN is not started,ignore the request"
		return 1
	fi
	if [ -f $CHANGED_FILE ]; then
		mv $CHANGED_FILE $CHANGED_FILE".prev"
	fi
	stop_lbd
	PHY_LIST_RESTART=""
	VIR_LIST_RESTART=""
	GUEST_LIST_RESTART=""
	for PHY_IF in $PHYSICAL_IF_LIST; do
		SYSCFG_INDEX=`syscfg_get "$PHY_IF"_syscfg_index`
		restart_required "physical" ${SYSCFG_INDEX}
		PHY_RESTART="$?"
		if [ "$PHY_RESTART" = "1" ] ; then
			ulog wlan status "${SERVICE_NAME}, physical changes detected: $PHY_IF"
			echo "${SERVICE_NAME}, physical changes detected: $PHY_IF"
			PHY_LIST_RESTART="`echo $PHY_LIST_RESTART` $PHY_IF"
		else	
			restart_required "virtual" ${SYSCFG_INDEX}
			VIR_RESTART="$?"
			if [ "$VIR_RESTART" = "1" ] ; then
				ulog wlan status "${SERVICE_NAME}, virtual changes detected: $PHY_IF"
				echo "${SERVICE_NAME}, virtual changes detected: $PHY_IF"
				VIR_LIST_RESTART="`echo $VIR_LIST_RESTART` $PHY_IF"
			else
				restart_required "guest" ${SYSCFG_INDEX}
				GUEST_RESTART="$?"
				if [ "$GUEST_RESTART" = "1" ]; then
					ulog wlan status "${SERVICE_NAME}, guest changes detected: $PHY_IF"
					echo "${SERVICE_NAME}, guest changes detected: $PHY_IF"
					GUEST_LIST_RESTART="`echo $GUEST_LIST_RESTART` $PHY_IF"
				fi
			fi
		fi
	done
	if [ -z "$PHY_LIST_RESTART" ] && [ -z "$VIR_LIST_RESTART" ] && [ -z "$GUEST_LIST_RESTART" ]; then
		start_lbd
		ulog wlan status "${SERVICE_NAME}, no wifi config changes detected,ignore the request"
		echo "${SERVICE_NAME}, no wifi config changes detected,ignore the request"
		sysevent set wifi_button_cnt 0
		return 1
	fi
	sysevent set ${SERVICE_NAME}-status starting
	for PHY_IF in $PHY_LIST_RESTART; do
		ulog wlan status "${SERVICE_NAME}, physical interface is required to restart: $PHY_IF"
		echo "${SERVICE_NAME}, physical interface is required to restart: $PHY_IF"
		wifi_virtual_stop $PHY_IF
		stop_hostapd $PHY_IF
		wifi_physical_stop $PHY_IF
		wifi_physical_start $PHY_IF
		wifi_virtual_start $PHY_IF
	done
	for PHY_IF in $VIR_LIST_RESTART; do
		SYSCFG_INDEX=`syscfg_get "$PHY_IF"_syscfg_index`
		VIR_IF=`syscfg_get "$SYSCFG_INDEX"_user_vap`
		if [ ! -z "$VIR_IF" ]; then
			ulog wlan status "${SERVICE_NAME}, virtual interface is required to restart: $PHY_IF"
			echo "${SERVICE_NAME}, virtual interface is required to restart: $PHY_IF"
			wifi_virtual_stop $PHY_IF
			stop_hostapd $PHY_IF
			wifi_virtual_start $PHY_IF
		fi
	done
	for PHY_IF in $GUEST_LIST_RESTART; do
		SYSCFG_INDEX=`syscfg_get "$PHY_IF"_syscfg_index`
		VIR_IF=`syscfg_get "$SYSCFG_INDEX"_guest_vap`
		if [ ! -z "$VIR_IF" ]; then
			ulog wlan status "${SERVICE_NAME}, guest interface is required to restart: $PHY_IF"
			echo "${SERVICE_NAME}, guest interface is required to restart: $PHY_IF"
			wifi_guest_restart $PHY_IF
		fi
	done
	if [ "" != "$PHY_LIST_RESTART" ] || [ "" != "$VIR_LIST_RESTART" ] ; then
		start_hostapd
	fi
	update_wifi_cache "physical"
	update_wifi_cache "virtual"
	update_wifi_cache "guest"
	if [ "`syscfg_get wl_wmm_support`" = "enabled" ] && [ "`syscfg_get wl0_network_mode`" = "11b" ]; then
        	VAP_IF=`syscfg_get wl0_physical_ifname`
        	iwpriv $VAP_IF setwmmparams 1 0 1 4
        	iwpriv $VAP_IF setwmmparams 1 1 1 4
        	iwpriv $VAP_IF setwmmparams 1 2 1 3
        	iwpriv $VAP_IF setwmmparams 1 3 1 2
        	iwpriv $VAP_IF setwmmparams 2 0 1 10
        	iwpriv $VAP_IF setwmmparams 2 1 1 10
        	iwpriv $VAP_IF setwmmparams 2 2 1 4
        	iwpriv $VAP_IF setwmmparams 2 3 1 3
	fi
	sysevent set ${SERVICE_NAME}-status started
	CNT=`sysevent get wifi_button_cnt`
	sysevent set wifi_button_cnt 1
	if [ "" = "${CNT}" ] || [ "0" = "${CNT}" ]; then
		sysevent set wifi_button_cnt 0
	else
		CNT=`expr $CNT % 2`
		if [ "0" = "${CNT}" ]; then
			echo 'valid wifi button event' > /dev/console
			sysevent set wifi_button-status pressed
			sysevent set wifi_config_changed
			sysevent set wifi_button_cnt 1
		else
			sysevent set wifi_button_cnt 0
		fi
	fi
	start_lbd
	return 0
}
wifi_renew_clients_handler()
{
	ulog wlan status "${SERVICE_NAME}, wifi_renew_clients_handler()"
	echo "${SERVICE_NAME}, wifi_renew_clients_handler()"
	sysevent set wifi_renew_clients-status starting
	wifi_refresh_interfaces
	sysevent set wifi_renew_clients-status started
}
start_hostapd()
{
	ulog wlan status "${SERVICE_NAME}, start_hostapd()"
	echo "${SERVICE_NAME}, start_hostapd()"
	USE_HOSTAPD=`syscfg_get wl_use_hostapd`
	HOSTAPD_CONF_LIST=""
	if [ "1" = "$USE_HOSTAPD" ]; then
		WL0STATE=`syscfg_get wl0_state`
		WL1STATE=`syscfg_get wl1_state`
		WL2STATE=`syscfg_get wl2_state`
		WL0SEC_MODE=`get_security_mode wl0_security_mode`
		WL1SEC_MODE=`get_security_mode wl1_security_mode`
		WL2SEC_MODE=`get_security_mode wl2_security_mode`
		if [ "up" = "$WL0STATE" ] && [ "8" != "$WL0SEC_MODE" ] && [ -f /tmp/hostapd-ath0.conf ] && [ ! -z "`echo $PHYSICAL_IF_LIST | grep ath0`" ]; then
			HOSTAPD_CONF_LIST="/tmp/hostapd-ath0.conf"
			PROC_PID_LINE=`ps | grep "hostapd-mon -v -0 /tmp/hostapd-ath0.conf" | grep -v grep`
			PROC_PID=`echo $PROC_PID_LINE |  awk '{print $1}'`
			if [ -z "$PROC_PID" ]; then
				hostapd-mon -v -0 /tmp/hostapd-ath0.conf &
			fi
			iwpriv ath0 authmode 5
			ulog wlan status "${SERVICE_NAME}, add ath0 to hostapd_conf_list, starting hostapd-mon for ath0"
		fi
		if [ "up" = "$WL1STATE" ] && [ "8" != "$WL1SEC_MODE" ] && [ -f /tmp/hostapd-ath1.conf ] && [ ! -z "`echo $PHYSICAL_IF_LIST | grep ath1`" ]; then
			HOSTAPD_CONF_LIST="`echo $HOSTAPD_CONF_LIST` /tmp/hostapd-ath1.conf"
			PROC_PID_LINE=`ps | grep "hostapd-mon -v -1 /tmp/hostapd-ath1.conf" | grep -v grep`
			PROC_PID=`echo $PROC_PID_LINE |  awk '{print $1}'`
			if [ -z "$PROC_PID" ]; then
				hostapd-mon -v -1 /tmp/hostapd-ath1.conf &
			fi
			iwpriv ath1 authmode 5
			ulog wlan status "${SERVICE_NAME}, add ath1 to hostapd_conf_list, starting hostapd-mon for ath1"
		fi
		if [ "up" = "$WL2STATE" ] && [ "8" != "$WL2SEC_MODE" ] && [ -f /tmp/hostapd-ath10.conf ] && [ ! -z "`echo $PHYSICAL_IF_LIST | grep ath10`" ]; then
			HOSTAPD_CONF_LIST="`echo $HOSTAPD_CONF_LIST` /tmp/hostapd-ath10.conf"
			PROC_PID_LINE=`ps | grep "hostapd-mon -v -2 /tmp/hostapd-ath10.conf" | grep -v grep`
			PROC_PID=`echo $PROC_PID_LINE |  awk '{print $1}'`
			if [ -z "$PROC_PID" ]; then
				hostapd-mon -v -2 /tmp/hostapd-ath10.conf &
			fi
			iwpriv ath10 authmode 5
			ulog wlan status "${SERVICE_NAME}, add ath10 to hostapd_conf_list, starting hostapd-mon for ath10"
		fi
		if [ "" != "$HOSTAPD_CONF_LIST" ]; then
			ulog wlan status "${SERVICE_NAME}, starting hostapd with $HOSTAPD_CONF_LIST"
			HOSTAPD_DEBUG=`syscfg_get wl_hostapd_debug`
			if [ ! -z "$HOSTAPD_DEBUG" ]; then
				HOSTAPD_CONF_LIST="`echo $HOSTAPD_DEBUG` `echo $HOSTAPD_CONF_LIST`"
			fi
			sysevent set hostapd_status start
			hostapd $HOSTAPD_CONF_LIST &
			SLEEP_WAIT=0
			while [ "$SLEEP_WAIT" -lt 10 ] && [ "running" != "`sysevent get hostapd_status`" ]; 
			do
				SLEEP_WAIT=`expr $SLEEP_WAIT + 1`
				sleep 1
			done
			if [ "running" != "`sysevent get hostapd_status`" ] ; then
				echo "${SERVICE_NAME}, !!!!!!Serious!!!!!! hostapd not running correctly (`date`)" > /dev/console
			fi
			sysevent set hostapd_status started
		fi
		if [ "up" = "$WL0STATE" ] && [ "0" = "$WL0SEC_MODE" ] && [ ! -z "`echo $PHYSICAL_IF_LIST | grep ath0`" ]; then
			iwconfig ath0 key off
		fi
		if [ "up" = "$WL1STATE" ] && [ "0" = "$WL1SEC_MODE" ] && [ ! -z "`echo $PHYSICAL_IF_LIST | grep ath1`" ]; then
			iwconfig ath1 key off
		fi
		if [ "up" = "$WL2STATE" ] && [ "0" = "$WL2SEC_MODE" ] && [ ! -z "`echo $PHYSICAL_IF_LIST | grep ath10`" ]; then
			iwconfig ath10 key off
		fi
		if [ "1" = "`syscfg_get guest_enabled`" ] && [ "1" = "`syscfg_get wl1_guest_enabled`" ] ; then
			GUEST_VAP=`syscfg_get wl1_guest_vap`
			iwconfig $GUEST_VAP freq 0
		fi
		if [ "1" = "`syscfg_get guest_enabled`" ] && [ "1" = "`syscfg_get wl2_guest_enabled`" ] ; then
			GUEST_VAP=`syscfg_get wl2_guest_vap`
			iwconfig $GUEST_VAP freq 0
		fi
		if [ "1" = "`syscfg_get guest_enabled`" ] && [ "1" = "`syscfg_get wl0_guest_enabled`" ] ; then
			GUEST_VAP=`syscfg_get wl0_guest_vap`
			iwconfig $GUEST_VAP freq 0
		fi
	fi
}
stop_hostapd()
{
	PHY_IF=$1
	killall hostapd > /dev/null 2>&1
	SYSCFG_INDEX=`syscfg_get "$PHY_IF"_syscfg_index`
	VIR_IF=`syscfg_get ${SYSCFG_INDEX}_user_vap`
	if [ -z "$VIR_IF" ]; then
		return 1
	fi
	get_wl_index $PHY_IF
	WL_INDEX=$?			 
	PROC_PID_LINE=`ps | grep "hostapd-mon -v -${WL_INDEX} /tmp/hostapd-${VIR_IF}.conf" | grep -v grep`
	PROC_PID=`echo $PROC_PID_LINE |  awk '{print $1}'`
	if [ -n "$PROC_PID" ]; then
		echo "${SERVICE_NAME}, stop process: ${PROC_PID_LINE} on ${VIR_IF}"
		kill -9 $PROC_PID > /dev/null 2>&1
	fi
	CONF_FILE=/tmp/hostapd-$VIR_IF.conf
	if [ -f $CONF_FILE ]; then
		mv $CONF_FILE ${CONF_FILE}.bak
	fi
	rm -f /tmp/hostapd-$VIR_IF.log		
	return 0	
}
start_lbd()
{
	ulog wlan status "${SERVICE_NAME}, start_lbd()"
	echo "${SERVICE_NAME}, start_lbd()"
	if [ "1" = "`syscfg get wifi::band_steering_enable`" ]; then
		[ ! -f /etc/init.d/lbd ] || /etc/init.d/lbd start
	fi
	return 0
}
stop_lbd()
{
	[ ! -f /etc/init.d/lbd ] || /etc/init.d/lbd stop
	return 0
}
ulog wlan status "${SERVICE_NAME}, sysevent received: $1"
service_init 
case "$1" in
	wifi-start)
		service_start
		;;
	wifi-stop)
		service_stop
		;;
	wifi-restart)
		service_restart
		;;
	wifi_user-start)
		if [ "`sysevent get ${SERVICE_NAME}-status`" = "started" ]; then
			wifi_user_start $2
		fi
		;;
	wifi_user-stop)
		if [ "`sysevent get ${SERVICE_NAME}-status`" = "started" ]; then
			wifi_user_stop $2
		fi
		;;
	wifi_user-restart)
		if [ "`sysevent get ${SERVICE_NAME}-status`" = "started" ]; then
			wifi_user_restart $2
		fi
		;;
	wifi_guest-start)
		if [ "`sysevent get ${SERVICE_NAME}-status`" = "started" ]; then
			wifi_guest_start $2
		fi
		;;
	wifi_guest-stop)
		if [ "`sysevent get ${SERVICE_NAME}-status`" = "started" ]; then
			wifi_guest_stop $2
		fi
		;;
	wifi_guest-restart)
		if [ "`sysevent get ${SERVICE_NAME}-status`" = "started" ]; then
			wifi_guest_restart $2
		fi
		;;
	wifi_config_changed)
		wifi_config_changed_handler
		;;
	wifi_renew_clients)
		wifi_renew_clients_handler
		;;
	lan-started)
		service_start
		;;
	mac_filter_changed)
		wifi_config_changed_handler
		;;	
	*)
	echo "Usage: service-${SERVICE_NAME} [ ${SERVICE_NAME}-start | ${SERVICE_NAME}-stop | ${SERVICE_NAME}-restart]" > /dev/console
		;;
esac
syscfg_commit
unlock $LOCK_FILE

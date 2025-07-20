#!/bin/sh
source /etc/init.d/ulog_functions.sh
source /etc/init.d/event_handler_functions.sh
source /etc/init.d/service_wifi/wifi_physical.sh
source /etc/init.d/service_wifi/wifi_sta_utils.sh
source /etc/init.d/syscfg_api.sh
source /etc/init.d/service_wifi/wifi_utils.sh
DEBUG_SETTING=`syscfg_get wifi_bridge_api_debug`
DEBUG() 
{
    [ "$DEBUG_SETTING" = "1" ] && $@
}
DEBUG set -x
COMMAND=$1
print_help()
{
	echo "Usage: wifi_bridge_api.sh is_connected"
	echo "       			get_conn_ssid"
	echo "       			get_conn_bssid"
	echo "       			get_conn_radio"
	echo "       			get_conn_network_mode"
	echo "       			get_conn_channel_width"
	echo "       			get_conn_channel"
	echo "       			get_conn_signal_strength"
	echo "       			get_wireless_networks <2.4GHz|5GHz>"
	echo "       			check_connection <ssid> <security> <radio> <passphrase>"
	exit
}
is_sta_connected()
{
	STA_VIR_IF=`syscfg_get wifi_sta_vir_if`
	if [ -z "$STA_VIR_IF" ]; then
		echo "error: no STA interface specified"
		exit
	fi
	if [ "Not-Associated" = "`iwconfig $STA_VIR_IF | grep Access | cut -d ':' -f 4 | tr -d '[[:space:]]'`" ]; then
		echo "no"
	else
		echo "yes"
	fi
}
get_ssid()
{
	syscfg_get wifi_bridge::ssid
}
get_bssid()
{
	echo "xx:xx:xx:xx:xx:xx"
}
get_radio()
{
	syscfg_get wifi_bridge::radio
}
get_network_mode()
{
	STA_VIR_IF="`syscfg_get wifi_sta_vir_if`"
	MODE="`iwpriv $STA_VIR_IF get_mode | cut -d ':' -f 2 | tr -d '[[:space:]]'`"
	case "$MODE" in
		"11B")
			echo "11b"
			;;
		"11G")
			if [ "1" = "`iwpriv $STA_VIR_IF get_pureg | cut -d ':' -f 2 | tr -d '[[:space:]]'`" ]; then
				echo "11g"
			else
				echo "11b 11g"
			fi
			;;
		"11NGHT20"|"11NGHT40PLUS"|"11NGHT40MINUS"|"11NGHT40")
			if [ "1" = "`iwpriv $STA_VIR_IF get_puren | cut -d ':' -f 2 | tr -d '[[:space:]]'`" ]; then
				echo "11n"
			else
				echo "11b 11g 11n"
			fi
			;;
		"11A")
			echo "11a"
			;;
		"11NAHT20"|"11NAHT40PLUS"|"11NAHT40MINUS")
			if [ "1" = "`iwpriv $STA_VIR_IF get_puren | cut -d ':' -f 2 | tr -d '[[:space:]]'`" ]; then
				echo "11n"
			else
				echo "11a 11n"
			fi
			;;
		"11ACVHT20"|"11ACVHT40PLUS"|"11ACVHT40MINUS"|"11ACVHT80")
			if [ "1" = "`iwpriv $STA_VIR_IF get_pure11ac | cut -d ':' -f 2 | tr -d '[[:space:]]'`" ]; then
				echo "11ac"
			else
				echo "11a 11n 11ac"
			fi
			;;
		"AUTO")
			echo "mixed"
			;;
		*)
			echo "mixed"
	esac
}
get_channel_width()
{
	STA_VIR_IF=`syscfg_get wifi_sta_vir_if`
	HTBW=`iwpriv $STA_VIR_IF get_chwidth | awk -F':' '{print $2}'`
	case "`echo $HTBW`" in
		"0")
		echo "auto"
		;;
		"2")
		echo "standard"
		;;
		"3")
		echo "wide"
		;;
		*)
		echo "error: unknown channel width"
	esac
	
}
get_channel()
{
	STA_VIR_IF=`syscfg_get wifi_sta_vir_if`
	iwlist $STA_VIR_IF channel | grep "(Channel" | awk '{print $NF}' | cut -c -2
}
get_connection_signal_strength()
{
	STA_VIR_IF=`syscfg_get wifi_sta_vir_if`
	if [ -z "$STA_VIR_IF" ]; then
		echo "error: no STA interface specified"
		exit
	fi
	SSID=`syscfg_get wifi_bridge::ssid | cut -c -11`
	wlanconfig $STA_VIR_IF list ap | grep $SSID | awk {'print $5'} | cut -d':' -f1
}
get_site_survey()
{
	RADIO=$1
	IF=""
	WLINDEX=""
	FILE="/tmp/site_survey"
	case "`echo $RADIO | tr [:upper:] [:lower:]`" in
		"2.4ghz")
		IF_1=ath0
		WLINDEX_1="wl0"
		
		;;
		"5ghz")
		IF_1=ath1
		WLINDEX_1="wl1"
		IF_2=ath10
		WLINDEX_2="wl2"
		;;
		*)
		echo "Usage: wifi_bridge_api.sh get_wireless_networks <2.4GHz|5GHz>"
		exit
	esac
	ifconfig $IF_1 up
	iwlist $IF_1 scan > /tmp/site_survey
	
	if [ $IF_2 != "" ];then
		ifconfig $IF_2 up
		iwlist $IF_2 scan >> /tmp/site_survey
	fi
	if [ "down" = `syscfg_get $WLINDEX_1"_state"` ]; then
		ifconfig $IF_1 down
	fi
	if [ $IF_2 != "" ] && [ "down" = `syscfg_get $WLINDEX_2"_state"` ];then
		ifconfig $IF_2 down
	fi
	ROW_LIST=`sed -n '/Cell [0-9]* - Address:/=' $FILE`
	APNUM=`echo $ROW_LIST | awk '{print NF}'`
	INDEX=1
	while [ ${INDEX} -le ${APNUM} ]
	do
		RESULTFILE="/tmp/bbb"
		if [  ${INDEX} -eq $APNUM ] ; then
			STARTROWNUM=`echo $ROW_LIST | awk '{print $"'$INDEX'" }' `
			sed -n "${STARTROWNUM},$ p" $FILE > ${RESULTFILE}
		else
			STARTROWNUM=`echo $ROW_LIST | awk '{print $"'$INDEX'" }' `
			ENDROWNUM=`expr ${INDEX} + 1`
			ENDROWNUM=`echo $ROW_LIST | awk '{print $"'$ENDROWNUM'" }' `
			ENDROWNUM=`expr ${ENDROWNUM} - 1`
			sed -n "${STARTROWNUM},${ENDROWNUM}p" $FILE > ${RESULTFILE}
		fi
		SSID=` grep 'ESSID:' ${RESULTFILE} | awk -F ':' '{print $2}'`
		SSID=`echo "${SSID%?}" | sed 's/"//' `
		if [ "$SSID" = "" ]; then
			INDEX=`expr $INDEX + 1`
			continue
		fi
		BSSID=` grep ' Address: ' ${RESULTFILE} | awk -F ': ' '{print $2}'`
		if [ "$BSSID" = "" ]; then
			INDEX=`expr $INDEX + 1`
			continue
		fi
	
		RSSI=`grep "Signal level=" ${RESULTFILE} | awk -F '=' '{print $3}' | awk '{print $1}'`
		if [ -n "`grep 'Encryption key:on' ${RESULTFILE}`" ] ; then
			SECURITY=`grep "IE:" ${RESULTFILE} | sed -n 1p | awk -F '/' '{print $2}' | awk '{print $1}' | sed -e s/"WPA"/"wpa-personal"/ -e s/"WPA2"/"wpa2-personal"/ -e s/"WPA-WPA2"/"wpa-mixed"/ `
		elif [ -n "`grep 'Encryption key:off' ${RESULTFILE}`"  ] ; then
			SECURITY="disabled"
		fi
		RADIO="$RADIO"
		echo "$SSID;$BSSID;$RSSI;$SECURITY;$RADIO"
		INDEX=`expr ${INDEX} + 1`
	done	
	
	exit
}
find_5G_SSID()
{
	DESIRED_SSID="$1"
	RESULT_FILE="/tmp/smart_scan_result"
	AP_LIST='/tmp/ap_list'
	AP_LIST_SORT='/tmp/ap_list_sort'
	SCAN_CNT=0
	rm -rf $RESULT_FILE
	if [ -e $AP_LIST ]; then
		rm $AP_LIST
	fi
	rm -rf $AP_LIST_SORT
	for i in 1 2; do
		if [ "1" = "$i" ];then
			IF="ath5"
			PHY_IF="wifi1"
		else
			IF="ath11"
			PHY_IF="wifi2"
		fi
		wlanconfig $IF create wlandev $PHY_IF wlanmode sta nosbeacon
		killall -9 wpa_supplicant
		CONF_FILE=/tmp/var/run/wpa_supplicant_$IF/$IF
		if [ -e $CONF_FILE ]; then
			rm -f $CONF_FILE
		fi
   		generate_wpa_supplicant "$IF" "$DESIRED_SSID" "none" "" "" > "/tmp/wpa_supplicant_$IF.conf"
   		wpa_supplicant -B -c "/tmp/wpa_supplicant_$IF.conf" -i $IF -b br0
		sysevent set smart_connect::scan_done 0
		sleep 1
		WPA_CNT=0
		while [ "1" != "`sysevent get smart_connect::scan_done`" ] && [ "$WPA_CNT" -lt 15 ];
		do 
			WPA_CNT=`expr $WPA_CNT + 1`
			sleep 1
		done
		sysevent set smart_connect::scan_done 0
		wpa_cli -p /var/run/wpa_supplicant_$IF -i $IF scan_results|grep "$DESIRED_SSID" > $RESULT_FILE
		while read scan_line
		do
			RESULTS="`echo $scan_line|awk '{print $1" "$5" "$2" "$3}'`"
			RESULT_SSID="`echo $RESULTS|awk '{print $2}'`"
			if [ "$RESULTS" = "bssid signal / frequency" ]; then
				continue
			fi
			if [ "$RESULT_SSID" != "$DESIRED_SSID" ];then
				continue
			fi
			if [ -z "$RESULTS" ];then
				continue
			fi
			TMP_FREQ="`echo $RESULTS|awk '{print $3}'`"
			change_freq_to_chan $TMP_FREQ
			TMP_CHAN=$?
			syscfg set wifi_sta_channel $TMP_CHAN
				
			echo "$RESULTS" >> $AP_LIST
			SCAN_CNT=`expr $SCAN_CNT + $i`
			break
		done < $RESULT_FILE
		rm -rf $RESULT_FILE
	done
	killall -9 wpa_supplicant
	sleep 2
	wlanconfig ath5 destroy
	wlanconfig ath11 destroy
	if [ "0" != "$SCAN_CNT" ];then 
		echo "wifi scan results: $SCAN_CNT AP(s)" > /dev/console 
		sort -n -r -k 4 $AP_LIST > $AP_LIST_SORT
		echo "  Scan results:" > /dev/console 
		cat $AP_LIST_SORT
	fi
	line=`head -n 1 $AP_LIST_SORT`
	USER_AP_FREQ="`echo $line | awk '{print $3}'`"
	change_freq_to_chan $USER_AP_FREQ
	USER_AP_CHAN=$?
	if [ "$USER_AP_CHAN" -gt "65" ];then
		SCAN_CNT=4
	fi
	echo "scan results:$SCAN_CNT" > /dev/console 
	return $SCAN_CNT
}
check_sta_connection()
{
	ulog wlan status "${SERVICE_NAME}, check_connection()"
	STA_SSID="$1"
	STA_SECURITY="$2"
	STA_RADIO="$3"	#2.4GHz or 5GHz
	STA_PASSPHRASE="$4"
	killall wpa_supplicant
	echo "${SERVICE_NAME}, check_connection(), this will disrupt the user and guest VAPs on $STA_RADIO" > /dev/console 
	if [ "2.4GHz" = "$STA_RADIO" ]; then
		OPMODE="11NGHT40PLUS"
		PHY_IF="wifi0"
		STA_IF="ath4"
		USER_IF="ath0"
		WLINDEX="wl0"
	elif [ "5GHz" = "$STA_RADIO" ]; then
		OPMODE="11ACVHT80"
		find_5G_SSID $STA_SSID
		ret="$?"
		if [ "0" = "$ret" ];then
			echo "${SERVICE_NAME}, check_connection, $STA_IF test connection to $STA_SSID was UNSUCCESSFUL" > /dev/console 
			sysevent set wifi_bridge_conn_status "failed"
			restore_wifi_settings wifi1 wl1 $STA_RADIO ath5
			return 1
		fi
		if [ "1" = "$ret" ];then
			PHY_IF="wifi1"
			STA_IF="ath5"
			USER_IF="ath1"
			WLINDEX="wl1"
		fi
		if [ "2" = "$ret" ];then
			PHY_IF="wifi2"
			STA_IF="ath11"
			USER_IF="ath10"
			WLINDEX="wl2"
		fi
		if [ "3" = "$ret" ];then
			PHY_IF="wifi1"
			STA_IF="ath5"
			USER_IF="ath1"
			WLINDEX="wl1"
			PHY_IF_2="wifi2"
			STA_IF_2="ath11"
			USER_IF_2="ath10"
			WLINDEX_2="wl2"
		fi
		if [ "4" = "$ret" ];then
			PHY_IF="wifi2"
			STA_IF="ath11"
			USER_IF="ath10"
			WLINDEX="wl2"
			PHY_IF_2="wifi1"
			STA_IF_2="ath5"
			USER_IF_2="ath1"
			WLINDEX_2="wl1"
		fi
	fi
	WPA_SUPPLICANT_CONF_TEST="/tmp/wpa_supplicant_${STA_IF}_test_conn.conf"
	sysevent set wifi_bridge_conn_status "connecting"
	wlanconfig $STA_IF create wlandev $PHY_IF wlanmode sta nosbeacon
	iwpriv $STA_IF mode $OPMODE
	iwconfig $STA_IF essid $STA_SSID mode managed
	iwpriv $STA_IF wds 0
	iwpriv $STA_IF extap 1
	ifconfig $PHY_IF up
	sleep 1
	echo "$SERVICE_NAME, bring up STA vap $STA_IF"
	ifconfig $STA_IF up
	sleep 1
	if [ "wpa-personal" = "$STA_SECURITY" ] || [ "wpa2-personal" = "$STA_SECURITY" ]; then
		generate_wpa_supplicant "$STA_IF" "$STA_SSID" "$STA_SECURITY" "$STA_PASSPHRASE" > $WPA_SUPPLICANT_CONF_TEST
		wpa_supplicant -B -c $WPA_SUPPLICANT_CONF_TEST -i $STA_IF -b br0
	fi
	
	COUNTER=0
	LINK_STATUS=0
	while [ $COUNTER -lt 15 ] && [ "0" = $LINK_STATUS ]
	do
		sleep 5
		if [ "Not-Associated" != "`iwconfig $STA_IF | grep Access | cut -d ':' -f 4 | tr -d '[[:space:]]'`" ]; then
			LINK_STATUS=1
			echo "${SERVICE_NAME}, check_connection, $STA_IF test connection to $STA_SSID was SUCCESSFUL" > /dev/console 
			sysevent set wifi_bridge_conn_status "success"
			syscfg set wifi_bridge::subband $WLINDEX
			syscfg set wifi_sta_phy_if $PHY_IF
			syscfg set wifi_sta_vir_if $STA_IF
			return 0
		fi
		COUNTER=`expr $COUNTER + 1`
	done
	if [ "" != "$PHY_IF_2" ];then
		WPA_SUPPLICANT_CONF_TEST="/tmp/wpa_supplicant_${STA_IF_2}_test_conn.conf"
		wlanconfig $STA_IF create wlandev $PHY_IF_2 wlanmode sta nosbeacon
		iwpriv $STA_IF_2 mode $OPMODE
		iwconfig $STA_IF_2 essid $STA_SSID mode managed
		iwpriv $STA_IF_2 wds 0
		iwpriv $STA_IF_2 extap 1
		ifconfig $PHY_IF_2 up
		sleep 1
		echo "$SERVICE_NAME, bring up STA vap $STA_IF_2"
		ifconfig $STA_IF_2 up
		sleep 1
		if [ "wpa-personal" = "$STA_SECURITY" ] || [ "wpa2-personal" = "$STA_SECURITY" ]; then
			generate_wpa_supplicant "$STA_IF_2" "$STA_SSID" "$STA_SECURITY" "$STA_PASSPHRASE" > $WPA_SUPPLICANT_CONF_TEST
			wpa_supplicant -B -c $WPA_SUPPLICANT_CONF_TEST -i $STA_IF_2 -b br0
		fi
	
		COUNTER=0
		LINK_STATUS=0
		while [ $COUNTER -lt 15 ] && [ "0" = $LINK_STATUS ]
		do
			sleep 5
			if [ "Not-Associated" != "`iwconfig $STA_IF_2 | grep Access | cut -d ':' -f 4 | tr -d '[[:space:]]'`" ]; then
				LINK_STATUS=1
				echo "${SERVICE_NAME}, check_connection, $STA_IF_2 test connection to $STA_SSID was SUCCESSFUL" > /dev/console 
				sysevent set wifi_bridge_conn_status "success"
				syscfg set wifi_bridge::subband $WLINDEX_2
				syscfg set wifi_sta_phy_if $PHY_IF_2
				syscfg set wifi_sta_vir_if $STA_IF_2
				return 0
			fi
			COUNTER=`expr $COUNTER + 1`
		done
	fi
	echo "${SERVICE_NAME}, check_connection, $STA_IF test connection to $STA_SSID was UNSUCCESSFUL" > /dev/console 
	sysevent set wifi_bridge_conn_status "failed"
	restore_wifi_settings $PHY_IF $WLINDEX $STA_RADIO $STA_IF
	if [ "" != "$PHY_IF_2" ];then
		restore_wifi_settings $PHY_IF_2 $WLINDEX_2 $STA_RADIO $STA_IF_2
	fi
	return 1
}
restore_wifi_settings()
{
	PHY_IF=$1
	WLINDEX=$2
	RADIO=$3
	STA_IF=$4
	WPA_SUPPLICANT_CONF_TEST="/tmp/wpa_supplicant_${STA_IF}_test_conn.conf"
	echo "${SERVICE_NAME}, restoring user defined settings on $RADIO"
	killall wpa_supplicant
	ifconfig $STA_IF down
	wlanconfig $STA_IF destroy
	rm -f $WPA_SUPPLICANT_CONF_TEST
	sysevent set wifi_sta_up 0
		sysevent set wifi-restart
	return 0
}
case "`echo $COMMAND`" in
	"is_connected")
	is_sta_connected
	;;
	"get_conn_ssid")
	get_ssid
	;;
	"get_conn_bssid")
	get_bssid
	;;
	"get_conn_radio")
	get_radio
	;;
	"get_conn_network_mode")
	get_network_mode
	;;
	"get_conn_channel_width")
	get_channel_width
	;;
	"get_conn_channel")
	get_channel
	;;
	"get_conn_signal_strength")
	get_connection_signal_strength
	;;
	"get_wireless_networks")
	get_site_survey "$2"
	;;
	"check_connection")
	check_sta_connection "$2" "$3" "$4" "$5"
	;;
	*)
	print_help
esac

VENDOR_2G_DEFINED_PHY_IFNAME=wdev0
VENDOR_5G_DEFINED_PHY_IFNAME=wdev1
SCRIPT_NAME="wifi_sta_utils"
WIFI_DEBUG_SETTING=`syscfg get ${SCRIPT_NAME}_debug`
DEBUG() 
{
    [ "$WIFI_DEBUG_SETTING" = "1" ] && $@
}
DEBUG set -x
radio_to_mrvl_physical_ifname()
{
	RADIO=$1
	IFNAME=""
	INDEX=""
	case "`echo $RADIO | tr [:upper:] [:lower:]`" in
		"2.4ghz")
		INDEX=0
		;;
		"5ghz")
		INDEX=1
		;;
	esac
	
	IFNAME=`syscfg get wl"$INDEX"_physical_ifname`
	echo "$IFNAME"
}
radio_to_mrvl_wl_index()
{
	RADIO=$1
	INDEX=""
	IF=`radio_to_mrvl_physical_ifname $RADIO`
	INDEX=`echo $IF | cut -c 5`
	echo $INDEX
}
get_site_survey()
{
	RADIO=$1
	IF=""
	case "`echo "$RADIO" | tr [:upper:] [:lower:]`" in
		"2.4ghz")
		IF=wdev0
		STA_MODE=7
		;;
		"5ghz")
		IF=wdev1
		STA_MODE=8
		;;
		*)
		echo "site survey error: invalid radio"
	esac
	STA_IF="$IF"sta0
	ifconfig "$STA_IF" up
	iwpriv "$STA_IF" stamode "$STA_MODE"
	sleep 1
	iwconfig "$STA_IF" commit
	iwpriv "$STA_IF" stascan 1
	sleep 5
	iwpriv "$STA_IF" getstascan
}
is_sta_connected()
{
	STA_IF=$1 #wdev0sta0 or wdev1sta0
	iwpriv $STA_IF getlinkstatus | awk -F':' '{print $2}'
}
get_stamode_from_interface()
{
	IFNAME=$1
	STAMODE=6
	case "`echo $IFNAME | cut -c 5`" in
		"0")
		STAMODE=7
		;;
		"1")
		STAMODE=8
		;;
	esac
	echo $STAMODE
}
prepare_sta_phy_if()
{
	IF=$1
	CHANNEL=`syscfg get wifi_sta_channel`
	ifconfig $IF up
	iwpriv "$IF" autochannel 1
	if [ -n "$CHANNEL" ]; then
		iwpriv "$IF" autochannel 1
		iwconfig "$IF" channel "$CHANNEL"
	else
		iwpriv "$IF" autochannel 1
	fi
	iwpriv "$IF" wmm 1
	iwpriv "$IF" htbw 0
	sleep 1
	iwconfig $IF commit
}
akm_type_detect()
{
	PHY_INTERFACE=$1
	INTERFACE="$1"sta0
	SSID=$2
	AP_SCAN_FILE=/tmp/ap_scan.txt
	AP_SCAN_ALL_FILE=/tmp/ap_scan_all.txt
	AP_CHANNEL_FILE=/tmp/ap_channel.txt
	SECURITY=""
	ENCRYPTION=""
	RETURN=""
	STAMODE=`get_stamode_from_interface $PHY_INTERFACE`
	IS_UP=""
	IS_UP=`ifconfig $PHY_INTERFACE | grep UP`
	if [ ! -n "$IS_UP" ]; then
		prepare_sta_phy_if $PHY_INTERFACE
	fi
	iwpriv $INTERFACE stamode $STAMODE
	iwpriv $INTERFACE macclone 1
	sleep 1
	iwconfig $INTERFACE commit 
	sleep 1
	ifconfig $INTERFACE up 
	iwpriv $INTERFACE stascan 1
	sleep 10
	iwpriv $INTERFACE getstascan > "$AP_SCAN_ALL_FILE"
	cat $AP_SCAN_ALL_FILE | grep $SSID" " > "$AP_SCAN_FILE"
	FILESIZE=`stat -c %s "$AP_SCAN_FILE"`
	if [ $FILESIZE -eq 0 ]; then
		echo "failed"
		return
	fi
	SECURITY=`cat $AP_SCAN_FILE | awk -F" " '{print $7}'`
	CHANNEL=`cat $AP_SCAN_FILE | awk -F" " '{print $4}'`
	echo $CHANNEL > "$AP_CHANNEL_FILE"
	if [ "$SECURITY" != "None" ]; then
		ENCRYPTION=`cat $AP_SCAN_FILE | awk -F " " '{print $8}'`
	fi
	case "$SECURITY" in
		"None")
		RETURN="open"
		;;
		"WPA")
		RETURN="wpa-personal"
		;;
		"WPA2")
		RETURN="wpa2-personal"
		;;
		"WPA-WPA2")
		RETURN="wpa-mixed"
		;;
		*)
		RETURN="open"
		;;
	esac
	echo "$RETURN"
}
wifi_sta_set_security()
{
	IF=$1
	SECURITY=$2
	PASSPHRASE="$3"
	case "$SECURITY" in
		"wpa-personal")
			iwpriv $IF wpawpa2mode 1
			iwpriv $IF ciphersuite "wpa tkip"
			iwpriv $IF passphrase "wpa $PASSPHRASE"
			;;
		"wpa2-personal")
			iwpriv $IF wpawpa2mode 2
			iwpriv $IF ciphersuite "wpa2 aes-ccmp"
			iwpriv $IF passphrase "wpa2 $PASSPHRASE"
			;;
		"wpa-mixed")
			iwpriv $IF wpawpa2mode 2
			iwpriv $IF ciphersuite "wpa2 aes-ccmp"
			iwpriv $IF passphrase "wpa2 $PASSPHRASE"
			;;
		*)
			iwpriv $IF wpawpa2mode 0
			;;
	esac
}
qca_24_amsdu_performance_fix()
{
	VIR_IF="$1"
	wifitool $VIR_IF beeliner_fw_test 85 1
	wifitool $VIR_IF beeliner_fw_test 86 66
	wifitool $VIR_IF beeliner_fw_test 87 70
}
generate_wpa_supplicant()
{
	STA_IF=$1
	SSID=$2
	SECURITY=$3
	PASSPHRASE=$4
	DESIRED_MAC=$5
	if [ "" != "$DESIRED_MAC" ]; then
		bssid="bssid=$DESIRED_MAC"
	else
		bssid=""
	fi
	if [ "64" != "${#PASSPHRASE}" ]; then
		PASSPHRASE=\"$PASSPHRASE\"
	fi
	if [ "wpa-personal" = "$SECURITY" ]; then
		cat <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant_$STA_IF
ap_scan=2
network={
	ssid="$SSID"
	$bssid
	proto=WPA
	key_mgmt=WPA-PSK
	pairwise=TKIP
	psk=$PASSPHRASE
}
EOF
	elif [ "none" = "$SECURITY" ];then
		cat <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant_$STA_IF
network={
	scan_ssid=1
	ssid="$SSID"
	$bssid
	proto=RSN
	key_mgmt=NONE
}
EOF
	else
		cat <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant_$STA_IF
network={
	scan_ssid=1
	ssid="$SSID"
	$bssid
	proto=RSN
	key_mgmt=WPA-PSK
	pairwise=CCMP TKIP
	psk=$PASSPHRASE
}
EOF
	fi
}
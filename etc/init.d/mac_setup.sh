#!/bin/sh

source /etc/init.d/syscfg_api.sh

#------------------------------------------------------------------
# © 2013 Belkin International, Inc. and/or its affiliates. All rights reserved.
#------------------------------------------------------------------
SERVICE_NAME="mac_setup"
WIFI_DEBUG_SETTING=`syscfg get ${SERVICE_NAME}_debug`
DEBUG() 
{
    [ "$WIFI_DEBUG_SETTING" = "1" ] && $@
}
DEBUG set -x

# This is a utility used to apply a mac address policy on Mamba
# This will populate all other MAC addesses based on the master MAC address
ETH0_MAC="$1"

echo "setting up MAC addresses for all interface based on $ETH0_MAC"
#--------------------------------------------------------------
# displaying the use of the fucntion
#--------------------------------------------------------------
display_usage()
{
	echo "Please check switch mac address" > /dev/console
	exit
}

#--------------------------------------------------------------
# this function applies the mac policy to the device
#--------------------------------------------------------------
processing() 
{
	# LAN MAC
	LAN_MAC=$ETH0_MAC

	# WAN MAC
	WAN_MAC=$ETH0_MAC

	#2.4G MAC address = WAN_MAC + 1
	W24G_MAC=`apply_mac_inc -m "$WAN_MAC" -i 1`

	# 5G MAC address = WAN_MAC + 2
	W5G_MAC=`apply_mac_inc -m "$WAN_MAC" -i 2`

	#second 5G MAC address = WAN_MAC +3
	W5G_2_MAC=`apply_mac_inc -m "$WAN_MAC" -i 3`

	# Guest MAC = WAN_MAC + 3 (first byte is admin byte)
	GUEST_MAC=`apply_mac_inc -m "$WAN_MAC" -i 4`
	GUEST_MAC=`apply_mac_adbit -m "$GUEST_MAC"`

	# 5G Guest MAC = WAN_MAC + 4 (first byte is admin byte)
	GUEST_MAC_5G=`apply_mac_inc -m "$WAN_MAC" -i 5`
	GUEST_MAC_5G=`apply_mac_adbit -m "$GUEST_MAC_5G"`

	# SimpleTap MAC = WAN_MAC + 5 (first byte is admin byte)
	TC_MAC=`apply_mac_inc -m "$WAN_MAC" -i 6`
	TC_MAC=`apply_mac_adbit -m "$TC_MAC"`

	# convert to upper case
	LAN_MAC=`echo $LAN_MAC | tr '[a-z]' '[A-Z]'`
	WAN_MAC=`echo $WAN_MAC | tr '[a-z]' '[A-Z]'`
	W24G_MAC=`echo $W24G_MAC | tr '[a-z]' '[A-Z]'`
	W5G_MAC=`echo $W5G_MAC | tr '[a-z]' '[A-Z]'`
	W5G_2_MAC=`echo $W5G_2_MAC | tr '[a-z]' '[A-Z]'`
	GUEST_MAC=`echo $GUEST_MAC | tr '[a-z]' '[A-Z]'`
	GUEST_MAC_5G=`echo $GUEST_MAC_5G | tr '[a-z]' '[A-Z]'`
	TC_MAC=`echo $TC_MAC | tr '[a-z]' '[A-Z]'`

	# This is common for all platforms
	syscfg_set lan_mac_addr $LAN_MAC
	syscfg_set wan_mac_addr $WAN_MAC
	syscfg_set wl0_mac_addr $W24G_MAC
	syscfg_set wl1_mac_addr $W5G_MAC
	syscfg_set wl2_mac_addr $W5G_2_MAC
	syscfg_set wl0.1_mac_addr $GUEST_MAC
	syscfg_set wl1.1_mac_addr $GUEST_MAC_5G
	syscfg_set wl0.2_mac_addr $TC_MAC
	return 0
}
default_wifi_network() {
	DEFAULT_SSID=`syscfg get device::default_ssid`
	DEFAULT_PASSPHRASE=`syscfg get device::default_passphrase`
	BAND_STEERING_ENABLE=`syscfg get wifi::band_steering_enable`
	BAND_STEERING_MODE=`syscfg get wifi::band_steering_mode`
	#syscfg_set wl0_ssid "$DEFAULT_SSID"
	#syscfg_set wl0_passphrase "$DEFAULT_PASSPHRASE"
	#syscfg_set wl1_ssid "${DEFAULT_SSID}_5GHz"

	#syscfg_set wl2_ssid "${DEFAULT_SSID}_5GHz"
	#syscfg_set wl2_ssid "$DEFAULT_SSID"
	#syscfg_set wl1_passphrase "$DEFAULT_PASSPHRASE"
	#syscfg_set wl2_passphrase "$DEFAULT_PASSPHRASE"

	if [ "1" = "$BAND_STEERING_ENABLE" ]; then
		if [ "2" = "$BAND_STEERING_MODE" ]; then
			syscfg_set wl1_ssid "$DEFAULT_SSID"
			syscfg_set wl2_ssid "$DEFAULT_SSID"
		elif [ "1" = "$BAND_STEERING_MODE" ]; then
			syscfg_set wl2_ssid "${DEFAULT_SSID}_5GHz"
		fi
	else
		syscfg_set wl2_ssid "${DEFAULT_SSID}_5GHz"
	fi
	syscfg_set wl2_passphrase "$DEFAULT_PASSPHRASE"
}
#--------------------------------------------------------------
# main entry
#--------------------------------------------------------------
if [ -z "$ETH0_MAC" ]; then
	display_usage
else
    processing
	VALIDATED=`syscfg get wl_params_validated`
	if [ "true" != "$VALIDATED" ]; then
		default_wifi_network
		syscfg_set wl_params_validated true
	fi
    syscfg_commit
fi
exit 0

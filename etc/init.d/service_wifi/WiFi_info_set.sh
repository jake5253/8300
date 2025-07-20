#!/bin/sh
source /etc/init.d/ulog_functions.sh
source /etc/init.d/syscfg_api.sh
US_CH_LIST_2G="1,2,3,4,5,6,7,8,9,10,11"
US_CH_LIST_5G="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
CA_CH_LIST_2G="1,2,3,4,5,6,7,8,9,10,11"
CA_CH_LIST_5G="36,40,44,48,52,56,60,64,100,104,108,112,116,132,136,140,149,153,157,161,165"
EU_CH_LIST_2G="1,2,3,4,5,6,7,8,9,10,11,12,13"
EU_CH_LIST_5G="36,40,44,48,52,56,60,64"
EU_CH_LIST_5GH="100,104,108,112,116,120,124,128,132,136,140"
AP_CH_LIST_2G="1,2,3,4,5,6,7,8,9,10,11,12,13"
AP_CH_LIST_5G="36,40,44,48,149,153,157,161,165"
AU_CH_LIST_2G="1,2,3,4,5,6,7,8,9,10,11,12,13"
AU_CH_LIST_5G="36,40,44,48"
AU_CH_LIST_5GH="149,153,157,161,165"
AH_CH_LIST_2G="1,2,3,4,5,6,7,8,9,10,11,12,13"
AH_CH_LIST_5G="36,40,44,48"
AH_CH_LIST_5GH="149,153,157,161,165"
NEED_RESTORE=FALSE
US_WL0_CH_WIDTHS="0,20"
US_WL0_CH_0="0,1,2,3,4,5,6,7,8,9,10,11"
US_WL0_CH_20="0,1,2,3,4,5,6,7,8,9,10,11"
US_WL1_CH_WIDTHS="0,20,40,80"
US_WL1_CH_0="0,36,40,44,48,52,56,60,64"
US_WL1_CH_20="0,36,40,44,48,52,56,60,64"
US_WL1_CH_40="0,36,40,44,48,52,56,60,64"
US_WL1_CH_80="0,36,40,44,48,52,56,60,64"
US_WL2_CH_WIDTHS="0,20,40,80"
US_WL2_CH_0="0,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
US_WL2_CH_20="0,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
US_WL2_CH_40="0,100,104,108,112,116,120,124,128,132,136,149,153,157,161"
US_WL2_CH_80="0,100,104,108,112,116,120,124,128,149,153,157,161"
CA_WL0_CH_WIDTHS="0,20"
CA_WL0_CH_0="0,1,2,3,4,5,6,7,8,9,10,11"
CA_WL0_CH_20="0,1,2,3,4,5,6,7,8,9,10,11"
CA_WL1_CH_WIDTHS="0,20,40,80"
CA_WL1_CH_0="0,36,40,44,48,52,56,60,64"
CA_WL1_CH_20="0,36,40,44,48,52,56,60,64"
CA_WL1_CH_40="0,36,40,44,48,52,56,60,64"
CA_WL1_CH_80="0,36,40,44,48,52,56,60,64"
CA_WL2_CH_WIDTHS="0,20,40,80"
CA_WL2_CH_0="0,100,104,108,112,116,132,136,140,149,153,157,161,165"
CA_WL2_CH_20="0,100,104,108,112,116,132,136,140,149,153,157,161,165"
CA_WL2_CH_40="0,100,104,108,112,132,136,149,153,157,161"
CA_WL2_CH_80="0,100,104,108,112,149,153,157,161"
EU_WL0_CH_WIDTHS="0,20"
EU_WL0_CH_0="0,1,2,3,4,5,6,7,8,9,10,11,12,13"
EU_WL0_CH_20="0,1,2,3,4,5,6,7,8,9,10,11,12,13"
EU_WL1_CH_WIDTHS="0,20,40,80"
EU_WL1_CH_0="0,36,40,44,48,52,56,60,64"
EU_WL1_CH_20="0,36,40,44,48,52,56,60,64"
EU_WL1_CH_40="0,36,40,44,48,52,56,60,64"
EU_WL1_CH_80="0,36,40,44,48,52,56,60,64"
EU_WL2_CH_WIDTHS="0,20,40,80"
EU_WL2_CH_0="0,100,104,108,112,116,120,124,128,132,136,140"
EU_WL2_CH_20="0,100,104,108,112,116,120,124,128,132,136,140"
EU_WL2_CH_40="0,100,104,108,112,116,120,124,128,132,136"
EU_WL2_CH_80="0,100,104,108,112,116,120,124,128"
AH_WL0_CH_WIDTHS="0,20"
AH_WL0_CH_0="0,1,2,3,4,5,6,7,8,9,10,11,12,13"
AH_WL0_CH_20="0,1,2,3,4,5,6,7,8,9,10,11,12,13"
AH_WL1_CH_WIDTHS="0,20,40,80"
AH_WL1_CH_0="0,36,40,44,48"
AH_WL1_CH_20="0,36,40,44,48"
AH_WL1_CH_40="0,36,40,44,48"
AH_WL1_CH_80="0,36,40,44,48"
AH_WL2_CH_WIDTHS="0,20,40,80"
AH_WL2_CH_0="0,149,153,157,161,165"
AH_WL2_CH_20="0,149,153,157,161,165"
AH_WL2_CH_40="0,149,153,157,161"
AH_WL2_CH_80="0,149,153,157,161"
SKU=`skuapi -g model_sku | awk -F"=" '{print $2}' | sed 's/ //g'`
PRODUCT=`echo $SKU | awk -F"-" '{print $1}'`
REGION_CODE=`skuapi -g cert_region | awk -F"=" '{print $2}' | sed 's/ //g'`
SYSCFG_REGION_CODE=`syscfg_get device::cert_region`
if [ -z "$SYSCFG_REGION_CODE" ]; then
	SYSCFG_REGION_CODE="$REGION_CODE"
fi
	wl0_available_channels=`syscfg_get wl0_available_channels`
	wl1_available_channels=`syscfg_get wl1_available_channels`
	case "$SYSCFG_REGION_CODE" in
		"US")
			syscfg_set device::cert_region "US"
			syscfg_set device::model_base "$PRODUCT"
			
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$US_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$US_CH_LIST_5G"
			fi
			if [ "`cat /etc/product`" = "nodes" ] || [ "`cat /etc/product`" = "dallas" ] || [ "`cat /etc/product`" = "xtrail" ] ; then
				syscfg_set wl1_available_channels "36,40,44,48,52,56,60,64"
				syscfg_set wl2_available_channels "100,104,108,112,116,120,124,128,149,153,157,161,165"
				syscfg_set wl0_supported_channel_widths "$US_WL0_CH_WIDTHS"
				syscfg_set wl0_available_channels_0 "$US_WL0_CH_0"
				syscfg_set wl0_available_channels_20 "$US_WL0_CH_20"
				syscfg_set wl1_supported_channel_widths "$US_WL1_CH_WIDTHS"
				syscfg_set wl1_available_channels_0 "$US_WL1_CH_0"
				syscfg_set wl1_available_channels_20 "$US_WL1_CH_20"
				syscfg_set wl1_available_channels_40 "$US_WL1_CH_40"
				syscfg_set wl1_available_channels_80 "$US_WL1_CH_80"
				syscfg_set wl2_supported_channel_widths "$US_WL2_CH_WIDTHS"
				syscfg_set wl2_available_channels_0 "$US_WL2_CH_0"
				syscfg_set wl2_available_channels_20 "$US_WL2_CH_20"
				syscfg_set wl2_available_channels_40 "$US_WL2_CH_40"
				syscfg_set wl2_available_channels_80 "$US_WL2_CH_80"
			fi
			syscfg_commit
			;;
		"EU")
			syscfg_set device::cert_region "EU"
			syscfg_set device::model_base "$PRODUCT"
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$EU_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$EU_CH_LIST_5G"
			fi
			if [ "`cat /etc/product`" = "nodes" ] || [ "`cat /etc/product`" = "dallas" ] || [ "`cat /etc/product`" = "xtrail" ] ; then
				if [ -z "$wl2_available_channels" ]; then
					syscfg_set wl2_available_channels "$EU_CH_LIST_5GH"
				fi
				syscfg_set wl0_supported_channel_widths "$EU_WL0_CH_WIDTHS"
				syscfg_set wl0_available_channels_0 "$EU_WL0_CH_0"
				syscfg_set wl0_available_channels_20 "$EU_WL0_CH_20"
				syscfg_set wl1_supported_channel_widths "$EU_WL1_CH_WIDTHS"
				syscfg_set wl1_available_channels_0 "$EU_WL1_CH_0"
				syscfg_set wl1_available_channels_20 "$EU_WL1_CH_20"
				syscfg_set wl1_available_channels_40 "$EU_WL1_CH_40"
				syscfg_set wl1_available_channels_80 "$EU_WL1_CH_80"
				syscfg_set wl2_supported_channel_widths "$EU_WL2_CH_WIDTHS"
				syscfg_set wl2_available_channels_0 "$EU_WL2_CH_0"
				syscfg_set wl2_available_channels_20 "$EU_WL2_CH_20"
				syscfg_set wl2_available_channels_40 "$EU_WL2_CH_40"
				syscfg_set wl2_available_channels_80 "$EU_WL2_CH_80"
				if [ "161" = "`syscfg get wl2_channel`" ] ; then
					syscfg_set wl2_channel 108
				fi
			fi
			syscfg_commit
			;;
		"ME")
			syscfg_set device::cert_region "ME"
			syscfg_set device::model_base "$PRODUCT"
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$EU_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$EU_CH_LIST_5G"
			fi
			if [ "`cat /etc/product`" = "nodes" ] || [ "`cat /etc/product`" = "dallas" ] || [ "`cat /etc/product`" = "xtrail" ] ; then
				if [ -z "$wl2_available_channels" ]; then
					syscfg_set wl2_available_channels "$EU_CH_LIST_5GH"
				fi
				syscfg_set wl0_supported_channel_widths "$EU_WL0_CH_WIDTHS"
				syscfg_set wl0_available_channels_0 "$EU_WL0_CH_0"
				syscfg_set wl0_available_channels_20 "$EU_WL0_CH_20"
				syscfg_set wl1_supported_channel_widths "$EU_WL1_CH_WIDTHS"
				syscfg_set wl1_available_channels_0 "$EU_WL1_CH_0"
				syscfg_set wl1_available_channels_20 "$EU_WL1_CH_20"
				syscfg_set wl1_available_channels_40 "$EU_WL1_CH_40"
				syscfg_set wl1_available_channels_80 "$EU_WL1_CH_80"
				syscfg_set wl2_supported_channel_widths "$EU_WL2_CH_WIDTHS"
				syscfg_set wl2_available_channels_0 "$EU_WL2_CH_0"
				syscfg_set wl2_available_channels_20 "$EU_WL2_CH_20"
				syscfg_set wl2_available_channels_40 "$EU_WL2_CH_40"
				syscfg_set wl2_available_channels_80 "$EU_WL2_CH_80"
				if [ "161" = "`syscfg get wl2_channel`" ] ; then
					syscfg_set wl2_channel 108
				fi
			fi
			syscfg_commit
			;;
		"AU")
			syscfg_set device::cert_region "AU"
			syscfg_set device::model_base "$PRODUCT"
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$AU_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$AU_CH_LIST_5G"
			fi
			if [ "`cat /etc/product`" = "nodes" ] || [ "`cat /etc/product`" = "dallas" ] || [ "`cat /etc/product`" = "xtrail" ] ; then
				if [ -z "$wl2_available_channels" ]; then
					syscfg_set wl2_available_channels "$AU_CH_LIST_5GH"
				fi
				syscfg_set wl0_supported_channel_widths "$AH_WL0_CH_WIDTHS"
				syscfg_set wl0_available_channels_0 "$AH_WL0_CH_0"
				syscfg_set wl0_available_channels_20 "$AH_WL0_CH_20"
				syscfg_set wl1_supported_channel_widths "$AH_WL1_CH_WIDTHS"
				syscfg_set wl1_available_channels_0 "$AH_WL1_CH_0"
				syscfg_set wl1_available_channels_20 "$AH_WL1_CH_20"
				syscfg_set wl1_available_channels_40 "$AH_WL1_CH_40"
				syscfg_set wl1_available_channels_80 "$AH_WL1_CH_80"
				syscfg_set wl2_supported_channel_widths "$AH_WL2_CH_WIDTHS"
				syscfg_set wl2_available_channels_0 "$AH_WL2_CH_0"
				syscfg_set wl2_available_channels_20 "$AH_WL2_CH_20"
				syscfg_set wl2_available_channels_40 "$AH_WL2_CH_40"
				syscfg_set wl2_available_channels_80 "$AH_WL2_CH_80"
			fi
			syscfg_commit
			;;
		"CA")
			syscfg_set device::cert_region "CA"
			syscfg_set device::model_base "$PRODUCT"
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$CA_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$CA_CH_LIST_5G"
			fi
			if [ "`cat /etc/product`" = "nodes" ] || [ "`cat /etc/product`" = "dallas" ] || [ "`cat /etc/product`" = "xtrail" ] ; then
				syscfg_set wl1_available_channels "36,40,44,48,52,56,60,64"
				syscfg_set wl2_available_channels "100,104,108,112,116,120,124,128,149,153,157,161,165"
				syscfg_set wl0_supported_channel_widths "$CA_WL0_CH_WIDTHS"
				syscfg_set wl0_available_channels_0 "$CA_WL0_CH_0"
				syscfg_set wl0_available_channels_20 "$CA_WL0_CH_20"
				syscfg_set wl1_supported_channel_widths "$CA_WL1_CH_WIDTHS"
				syscfg_set wl1_available_channels_0 "$CA_WL1_CH_0"
				syscfg_set wl1_available_channels_20 "$CA_WL1_CH_20"
				syscfg_set wl1_available_channels_40 "$CA_WL1_CH_40"
				syscfg_set wl1_available_channels_80 "$CA_WL1_CH_80"
				syscfg_set wl2_supported_channel_widths "$CA_WL2_CH_WIDTHS"
				syscfg_set wl2_available_channels_0 "$CA_WL2_CH_0"
				syscfg_set wl2_available_channels_20 "$CA_WL2_CH_20"
				syscfg_set wl2_available_channels_40 "$CA_WL2_CH_40"
				syscfg_set wl2_available_channels_80 "$CA_WL2_CH_80"
			fi
			syscfg_commit
			;;
		"AP")
			syscfg_set device::cert_region "AP"
			syscfg_set device::model_base "$PRODUCT"
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$AP_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$AP_CH_LIST_5G"
			fi
			syscfg_commit
			;;
		"AH")
			syscfg_set device::cert_region "AH"
			syscfg_set device::model_base "$PRODUCT"
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$AH_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$AH_CH_LIST_5G"
			fi
			if [ "`cat /etc/product`" = "nodes" ] || [ "`cat /etc/product`" = "dallas" ] || [ "`cat /etc/product`" = "xtrail" ] ; then
				if [ -z "$wl2_available_channels" ]; then
					syscfg_set wl2_available_channels "$AH_CH_LIST_5GH"
				fi
				syscfg_set wl0_supported_channel_widths "$AH_WL0_CH_WIDTHS"
				syscfg_set wl0_available_channels_0 "$AH_WL0_CH_0"
				syscfg_set wl0_available_channels_20 "$AH_WL0_CH_20"
				syscfg_set wl1_supported_channel_widths "$AH_WL1_CH_WIDTHS"
				syscfg_set wl1_available_channels_0 "$AH_WL1_CH_0"
				syscfg_set wl1_available_channels_20 "$AH_WL1_CH_20"
				syscfg_set wl1_available_channels_40 "$AH_WL1_CH_40"
				syscfg_set wl1_available_channels_80 "$AH_WL1_CH_80"
				syscfg_set wl2_supported_channel_widths "$AH_WL2_CH_WIDTHS"
				syscfg_set wl2_available_channels_0 "$AH_WL2_CH_0"
				syscfg_set wl2_available_channels_20 "$AH_WL2_CH_20"
				syscfg_set wl2_available_channels_40 "$AH_WL2_CH_40"
				syscfg_set wl2_available_channels_80 "$AH_WL2_CH_80"
			fi
			syscfg_commit
			;;
		"PH")
			syscfg_set device::cert_region "PH"
			syscfg_set device::model_base "$PRODUCT"
			if [ -z "$wl0_available_channels" ]; then
				syscfg_set wl0_available_channels "$AP_CH_LIST_2G"
			fi
			if [ -z "$wl1_available_channels" ]; then
				syscfg_set wl1_available_channels "$AP_CH_LIST_5G"
			fi
			syscfg_commit
			;;
		"HK")
			syscfg_set device::cert_region "HK"
			syscfg_set device::model_base "$PRODUCT"
			syscfg_set wl0_available_channels "1,2,3,4,5,6,7,8,9,10,11"
			syscfg_set wl1_available_channels "36,40,44,48,149,153,157,161,165"
			if [ "`cat /etc/product`" = "nodes" -o "`cat /etc/product`" = "rogue" -o "`cat /etc/product`" = "dallas" ] ; then
				syscfg_set wl1_available_channels "36,40,44,48"
				syscfg_set wl2_available_channels "149,153,157,161,165"
				syscfg_set wl0_supported_channel_widths "0,20"
				syscfg_set wl0_available_channels_0 "0,1,2,3,4,5,6,7,8,9,10,11"
				syscfg_set wl0_available_channels_20 "0,1,2,3,4,5,6,7,8,9,10,11"
				syscfg_set wl1_supported_channel_widths "0,20,40"
				syscfg_set wl1_available_channels_0 "0,36,40,44,48"
				syscfg_set wl1_available_channels_20 "0,36,40,44,48"
				syscfg_set wl1_available_channels_40 "0,36,40,44,48"
				if [ "1" = "`syscfg get wl1_dfs_enabled`" ];then
					syscfg_set wl1_available_channels "36,40,44,48,52,56,60,64"
					syscfg_set wl1_available_channels_0 "0,36,40,44,48,52,56,60,64"
					syscfg_set wl1_available_channels_20 "0,36,40,44,48,52,56,60,64"
					syscfg_set wl1_available_channels_40 "0,36,40,44,48,52,56,60,64"
				fi
				syscfg_set wl2_supported_channel_widths "0,20,40"
				syscfg_set wl2_available_channels_0 "0,149,153,157,161,165"
				syscfg_set wl2_available_channels_20 "0,149,153,157,161,165"
				syscfg_set wl2_available_channels_40 "0,149,153,157,161"
				if [ "1" = "`syscfg get wl2_dfs_enabled`" ] ; then
					syscfg_set wl2_available_channels "100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
					syscfg_set wl2_available_channels_0 "0,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
					syscfg_set wl2_available_channels_20 "0,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165"
					syscfg_set wl2_available_channels_40 "0,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161"
				fi
			fi
			syscfg_commit
			;;
		*)
			ulog wlan status "wifi, Invalid region code, could not set on WiFi" > /dev/console
			;;
	esac
	ulog wlan status "wifi, Channel list and region code is set on syscfg" > /dev/console

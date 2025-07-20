#!/bin/sh
source /etc/init.d/service_wifi/wifi_utils.sh
source /etc/init.d/ulog_functions.sh
source /etc/init.d/event_handler_functions.sh
source /etc/init.d/syscfg_api.sh
wifi_simpletap_start ()
{
	return 0
}
wifi_simpletap_stop ()
{
	return 0
}
wifi_simpletap_restart()
{
	wifi_simpletap_stop
	wifi_simpletap_start
	return 0
}
unsecure_page()
{
	return 0
}
set_driver_regioncode()
{
	PHY_IF=$1
	REGION=`syscfg_get device::cert_region`
	case "$REGION" in
		"EU")
			REGION_CODE="826"
			;;
		"AU")
			REGION_CODE="554"
			;;
		"CA")
			REGION_CODE="5001"
			;;
		"AP")
			REGION_CODE="400"
			;;
		"AH")
			REGION_CODE="458"
			;;
		"PH")
			REGION_CODE="608"
			;;
		"HK")
			REGION_CODE="344"
			;;
		"ME")
			REGION_CODE="826"
			;;
		*)
			REGION_CODE="843"
			;;
	esac
	INT=`get_phy_interface_name_from_vap "$PHY_IF"`
	iwpriv $INT setCountryID $REGION_CODE
	return 0
}
set_driver_dfs() 
{
	PHY_IF=$1
	SYSCFG_INDEX=`syscfg_get "$PHY_IF"_syscfg_index`
	DFS=`syscfg_get "$SYSCFG_INDEX"_dfs_enabled`
	INT=`get_phy_interface_name_from_vap "$PHY_IF"`
	if [ "1" = "$DFS" ]; then
		iwpriv $INT blockdfslist 0
	else
		iwpriv $INT blockdfslist 1
	fi
	REGION=`syscfg_get device::cert_region`
	if [ "IN" = "$REGION" -o "HK" = "$REGION" ] && [ "`cat /etc/product`" = "nodes" -o "`cat /etc/product`" = "nodes-jr" -o "`cat /etc/product`" = "dallas" ] && [ "$SYSCFG_INDEX" = "wl0" ] ; then
		wifitool $PHY_IF block_acs_channel 0
		wifitool $PHY_IF block_acs_channel 12,13
	fi
	if [ "EU" = "$REGION" -o "ME" = "$REGION" -o "JP" = "$REGION" ] && [ "`cat /etc/product`" = "dallas" ] && [ "$SYSCFG_INDEX" = "wl2" ] ; then
		iwpriv $INT blockdfslist 0
		wifitool $PHY_IF block_acs_channel 0
		iwpriv $PHY_IF no_wradar 1
		wifitool $PHY_IF block_acs_channel 116,120,124,128
	fi
}
set_driver_adaptivity() 
{
	PHY_IF=$1
	REGION=`syscfg_get device::cert_region`
	INT=`get_phy_interface_name_from_vap "$PHY_IF"`
	if [ "$REGION" = "EU" ]; then
		iwpriv $INT aggr_burst 0 0
	fi
}

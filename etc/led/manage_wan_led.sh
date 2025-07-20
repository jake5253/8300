#!/bin/sh
#
#------------------------------------------------------------------
# © 2013 Belkin International, Inc. and/or its affiliates. All rights reserved.
#------------------------------------------------------------------
#
# Manages WAN LED
#
# normal wan is green (front internet). 
#
# If link is down, flash front internet LED on/off (physical connection problem)
#
# If Belkin ICC (Internet Connection Checking) is disabled, the as long as the
# WAN proto is up, then it will be solid 'on'.
#


#check if UI disable all led
#LED_STATUS=`syscfg get led_ui_rearport`
#if [ "0" == "${LED_STATUS}" ]; then
#	exit 0 
#fi

SetUp=`syscfg get User_Accepts_WiFi_Is_Unsecure`
#keep solid before set up
if [ "1" != "$SetUp" ]; then
	echo default-on > /sys/class/leds/internet/trigger
fi

while [ "1" != "$SetUp" ]; do
	sleep 2
	SetUp=`syscfg get User_Accepts_WiFi_Is_Unsecure`
done



bridge_mode=`syscfg get bridge_mode`
if [ $bridge_mode == "0" ]; then
    # ------------------------------------------------------------------------
    # Router mode 
    # - ICC is running
    # - phylink_wan_state indicates WAN physical Ethernet link
    # - wan_status indicates protocol up
    # - icc_internet_state indicates internet connectivity
    # ------------------------------------------------------------------------
	#cbt add for phy wan diag

	#change the phy detect tool to qca 
	PHY=`ssdk_sh port linkstatus get 5 |grep SSDK |(sed -n 's/.*'Status]:'/ /p')`
	if [ $PHY == "ENABLE" ]; then
		echo none > /sys/class/leds/diag/trigger
	else
		echo default-on > /sys/class/leds/diag/trigger
		#close cbt_icc check to prevent the internet led on
		#killall cbt_icc
		#echo none > /sys/class/leds/internet/trigger
        	echo default-on > /sys/class/leds/internet/trigger
		exit 0
	fi
    wan_status=`sysevent get wan-status`
    if [ "$wan_status" != "started" ]
    then
        # link up but protocol down
        #echo timer > /sys/class/leds/internet/trigger
	#	echo "714" > /sys/class/leds/internet/delay_on
	#	echo "714" > /sys/class/leds/internet/delay_off
        echo default-on > /sys/class/leds/internet/trigger
        exit 0
    fi

    #icc_enabled=`syscfg get belkin_icc_enabled`
    #if [ "$icc_enabled" == 1 ]; then
    #    state=`sysevent get icc_internet_state`
    #    if [ "$state" != "up" ]; then
            # link up, protocol up, but internet down
    #    	echo default-on > /sys/class/leds/internet/trigger
#		exit 0
#        fi	
    #fi




    # link up, protocol up, and internet up/no internet checking
    echo none > /sys/class/leds/internet/trigger
	PID=$(pidof cbt_icc.sh)
	if [[ -z $PID ]]; then
                /etc/led/cbt_icc.sh cbt_check &
	fi
else	
	#in bridge mode, diag , internet led should be always off	
	echo none > /sys/class/leds/diag/trigger
	echo none > /sys/class/leds/internet/trigger
	exit 0
fi


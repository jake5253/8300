#!/bin/sh

MAXWAIT=120
CNT=0;

#check if UI disable all led
#LED_STATUS=`syscfg get led_ui_rearport`
#if [ "0" == "${LED_STATUS}" ]; then
#	exit 0 
#fi

#cbt fix dallas-128 : close wps_failed.sh before restart wps button
echo none >/sys/class/leds/wps_amber/trigger 
killall wps_failed.sh


if [ -d /sys/class/leds/wps ]; then
	echo timer > /sys/class/leds/wps/trigger
	echo "501" > /sys/class/leds/wps/delay_on
	echo "501" > /sys/class/leds/wps/delay_off
	#sleep 120

	#Instead of sleeping for 120s, create a counter and sleep in increments of 2s
	#Every 2s check if wps completed, if so exit the script
	while [ $CNT -lt $MAXWAIT ]
	do
		STATE=`sysevent get wps_process`
		if [ "completed" = "$STATE" ]; then
			echo "`date` LED $0 $1 $2 $3" >> /var/log/messages
			exit;
		fi

		sleep 2;
		CNT=`expr $CNT + 2`
	done
	
	#There is a race condition when this is triggered... 
	#and when solid_wps.sh is triggered from sysevent wps-success.
	#Because of the "sleep 120," this would trigger after solid_wps.sh 	
	echo none > /sys/class/leds/wps/trigger
	
	#Must call to make sure no race condition occurs.
	/etc/led/manage_wan_led.sh
	
fi

echo "`date` LED $0 $1 $2 $3" >> /var/log/messages


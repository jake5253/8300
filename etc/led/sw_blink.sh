#!/bin/sh

DECI_SECS=$1

#check if UI disable all led
#LED_STATUS=`syscfg get led_ui_rearport`
#if [ "0" == "${LED_STATUS}" ]; then
#	exit 0 
#fi

if [ -z $DECI_SECS ]; then
	DECI_SECS=10;
fi
if [ -d /sys/class/leds ]; then
	echo timer > /sys/class/leds/panel/trigger
fi

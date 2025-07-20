#!/bin/sh
#check if UI disable all led
LED_STATUS=`syscfg get led_ui_rearport`
if [ "0" == "${LED_STATUS}" ]; then
	exit 0 
fi

/etc/led/blink.sh

echo "`date` LED $0 $1 $2 $3" >> /var/log/messages


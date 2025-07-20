#!/bin/sh
#check if UI disable all led
LED_STATUS=`syscfg get led_ui_rearport`
if [ "0" == "${LED_STATUS}" ]; then
	exit 0 
fi

# Blink LED on network activity (tx/rx). 
label=pwr
net_name=br0
blink_mode="tx rx"
#blink mode can be "tx rx link"
if [ -d /sys/class/leds/$label ]; then
	if [ $1 = "on" ]; then
	echo netdev > /sys/class/leds/$label/trigger
	echo "$net_name" > /sys/class/leds/$label/device_name
	echo "$blink_mode" > /sys/class/leds/$label/mode
	elif [ $1 = "off" ]; then
	echo none > /sys/class/leds/$label/trigger
	fi
fi

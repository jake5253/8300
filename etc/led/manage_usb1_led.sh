#!/bin/sh
#
# Manages USB1 LED
#
# USB1 is combo eSata/USB port, 2.0 and legacy only
#
# $1 is usb_port_1_state
# $2 is the event value
#

#LED_CTRL=/proc/bdutil/leds
LED_CTRL=/sys/class/leds/usb
PID=$(pidof usb_data.sh)


if [ ! -e $LED_CTRL ]
then
    exit 0
fi

if [ "$2" == "up" ]
then
    type=`sysevent get usb_port_1_type`
    if [ "$type" == "storage" -o "$type" == "printer" ]
    then
        #echo "usb1=on" > $LED_CTRL
	echo "default-on" > /sys/class/leds/usb/trigger
	#bring up data led daemon
	if [[ -z $PID ]]; then
		#echo no process, bring up: /etc/led/usb_data.sh;	
        	/etc/led/usb_data.sh &
        	exit 0
	fi
		#echo /etc/led/usb_data.sh is exist , leave ~;	
    fi
fi


#close usb data led
if [ "$2" == "down" ]
then
	killall usb_data.sh
fi
echo "none" > /sys/class/leds/usb/trigger
#echo "usb1=off" > $LED_CTRL
        

#!/bin/sh
#
# USB1 umount event
#
# USB1 is combo eSata/USB port, 2.0 and legacy only
#

#LED_CTRL=/proc/bdutil/leds
LED_CTRL=/sys/class/leds/usb

if [ ! -e $LED_CTRL ]
then
    exit 0
fi

#close usb data led
killall usb_data.sh
echo "none" > /sys/class/leds/usb/trigger
#echo "usb1=off" > $LED_CTRL


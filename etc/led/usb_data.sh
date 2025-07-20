#!/bin/sh
while :
do

	data1=`cat /proc/interrupts  |grep xhci-hcd:usb1 | awk '{print $2}'`
	usleep 500000
	data2=`cat /proc/interrupts  |grep xhci-hcd:usb1 | awk '{print $2}'`


	if [ $data1 == $data2 ]; then
		#echo "NO data......"
		echo 'default-on' > /sys/class/leds/usb/trigger	
	else
		#echo "USB data running!!!"
		echo timer > /sys/class/leds/usb/trigger
                echo "100" > /sys/class/leds/usb/delay_on
                echo "100" > /sys/class/leds/usb/delay_off	
	fi

done


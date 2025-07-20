#!/bin/sh
#put it to power-on default state !
#For Civic this means all controllable LEDs are off
#Use sysfs interface
if [ -d /sys/class/leds ]; then
	echo default-on > /sys/class/leds/panel/trigger
fi

ssdk_sh debug phy set 0 0xd 0x7
ssdk_sh debug phy set 0 0xe 0x8074
ssdk_sh debug phy set 0 0xd 0x4007
ssdk_sh debug phy set 0 0xe 0x0670

ssdk_sh debug phy set 1 0xd 0x7
ssdk_sh debug phy set 1 0xe 0x8074
ssdk_sh debug phy set 1 0xd 0x4007
ssdk_sh debug phy set 1 0xe 0x0670

ssdk_sh debug phy set 2 0xd 0x7
ssdk_sh debug phy set 2 0xe 0x8074
ssdk_sh debug phy set 2 0xd 0x4007
ssdk_sh debug phy set 2 0xe 0x0670

ssdk_sh debug phy set 3 0xd 0x7
ssdk_sh debug phy set 3 0xe 0x8074
ssdk_sh debug phy set 3 0xd 0x4007
ssdk_sh debug phy set 3 0xe 0x0670

ssdk_sh debug phy set 4 0xd 0x7
ssdk_sh debug phy set 4 0xe 0x8074
ssdk_sh debug phy set 4 0xd 0x4007
ssdk_sh debug phy set 4 0xe 0x0670

ssdk_sh debug phy set 0 0xd 0x7
ssdk_sh debug phy set 0 0xe 0x8076
ssdk_sh debug phy set 0 0xd 0x4007
ssdk_sh debug phy set 0 0xe 0x70

ssdk_sh debug phy set 1 0xd 0x7
ssdk_sh debug phy set 1 0xe 0x8076
ssdk_sh debug phy set 1 0xd 0x4007
ssdk_sh debug phy set 1 0xe 0x70

ssdk_sh debug phy set 2 0xd 0x7
ssdk_sh debug phy set 2 0xe 0x8076
ssdk_sh debug phy set 2 0xd 0x4007
ssdk_sh debug phy set 2 0xe 0x70

ssdk_sh debug phy set 3 0xd 0x7
ssdk_sh debug phy set 3 0xe 0x8076
ssdk_sh debug phy set 3 0xd 0x4007
ssdk_sh debug phy set 3 0xe 0x70

ssdk_sh debug phy set 4 0xd 0x7
ssdk_sh debug phy set 4 0xe 0x8076
ssdk_sh debug phy set 4 0xd 0x4007
ssdk_sh debug phy set 4 0xe 0x70

/etc/led/manage_wan_led.sh 
echo "`date` LED $0 $1 $2 $3" >> /var/log/messages


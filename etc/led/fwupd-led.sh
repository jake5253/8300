#!/bin/sh

FU_Blink()
{
    echo default-on > /sys/class/leds/panel/trigger
	sleep $1
	echo none > /sys/class/leds/panel/trigger
	sleep $2
}

FU_Start()
{
	echo timer  > /sys/class/leds/panel/trigger
	echo "700" > /sys/class/leds/panel/delay_on
	echo "700" > /sys/class/leds/panel/delay_off
}

FU_Start2()
{
	echo timer  > /sys/class/leds/panel/trigger
	echo "1000" > /sys/class/leds/panel/delay_on
	echo "1000" > /sys/class/leds/panel/delay_off
}

FU_Failed()
{
	echo none > /sys/class/leds/panel/trigger
}

FU_Failed2()
{
	echo none > /sys/class/leds/panel/trigger
}

FU_Success()
{
	echo default-on > /sys/class/leds/panel/trigger
}

FU_Success2()
{
	LED_SIGNAL="$(syscfg get fwup_forced_led)"

	case "$LED_SIGNAL" in

		"solid")
			FU_Success
			;;

		"blink")
			echo timer  > /sys/class/leds/panel/trigger
			echo "100" > /sys/class/leds/panel/delay_on
			echo "100" > /sys/class/leds/panel/delay_off
			;;
		*)
			FU_Success
			;;
	esac
}


case "$1" in

	"fu_start")
		FU_Start
		;;

	"fu_start2")
		FU_Start2
		;;

	"fu_failed")
		FU_Failed
		;;

	"fu_failed2")
		FU_Failed2
		;;

	"fu_success")
		FU_Success
		;;

	"fu_success2")
		FU_Success2
		;;

	*)
		;;
esac

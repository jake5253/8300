#!/bin/sh

SetTimer()
{
        sysevent set led_timeout_sec $1
}

GetTimer()
{
        RET_VAL=$(sysevent get led_timeout_sec)
        if [ -z ${RET_VAL} ]; then
		RET_VAL=0
	fi

        echo ${RET_VAL}
}

DecTimer()
{
        TIME_OUT=$(GetTimer)
        if [ $TIME_OUT -lt 1 ]; then
                TIME_OUT=1;
        fi
        TIME_OUT=$(expr $TIME_OUT - 1)
        SetTimer $TIME_OUT
}

WaitTillTimeout()
{
        while [ $(GetTimer) -gt 0 ]
        do
                ## debug show timer
                # echo $(GetTimer)
                sleep 1
                DecTimer
        done

        SetTimer 0

        # go to solid LED
        if [ -d /sys/class/leds ]; then
                /etc/led/lib_set_solid.sh
        fi
}

SetSolidAfter()
{
        TIME_OUT=$(GetTimer)
        if [ 0 != $TIME_OUT ]; then
                SetTimer $1
        else
                SetTimer $1
                WaitTillTimeout $1
        fi
}


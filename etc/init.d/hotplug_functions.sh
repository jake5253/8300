#!/bin/sh
Hotplug_GetDevpath()
{
    DEVICE_PATH=
    local devname=${1::3}
    local udevdata 
    udevdata=`udevadm info --query=all --name=$devname 2> /dev/null`
    if [ "$?" != 0 ]; then
        ulog usb autodetect "$PID Hotplug_GetDevpath: $devname not found"
        return
    fi
    DEVICE_PATH=`echo "$udevdata" | grep PHYSDEVPATH | sed 's/^E: PHYSDEVPATH=\(.*\)/\1/'`
}
Hotplug_GetId()
{
    DEVICE_TYPE="usb"
    DEVICE_PORT=
    local devname=$1
    Hotplug_GetDevpath "$devname"
    Hotplug_GetIdFromDevpath "$DEVICE_PATH"
}
Hotplug_GetIdFromDevpath()
{
    DEVICE_TYPE="usb"
    DEVICE_PORT=
    local devpath="$1"
    get_count_usb_host
    if [ "$USB_HOST_CNT" -gt "1" ] ; then
        get_usb_port_from_multiple_host "$devpath"
    else
        get_usb_port_from_single_host "$devpath"
    fi
    DEVICE_PORT=$USB_port
    ulog usb autodetect "$PID Hotplug_GetIdFromDevpath: $DEVICE_TYPE $DEVICE_PORT"
}
Hotplug_GetInfo()
{
    DEVICE_VENDOR=
    DEVICE_MODEL=
    DEVICE_SPEED=
    local devname=$1
    Hotplug_GetDevpath "$devname"
    Hotplug_GetInfoFromDevpath "$DEVICE_PATH"
}
Hotplug_GetInfoFromDevpath()
{
    DEVICE_VENDOR=
    DEVICE_MODEL=
    DEVICE_SPEED=
    local devpath=$1
    local dir=`echo $devpath | sed 's/^\/\(.*usb[0-9]*\/[^\/]*\).*/\1/'`
    if [ -f "/sys/$dir/manufacturer" ]; then
        DEVICE_VENDOR=`cat /sys/$dir/manufacturer`
    fi
    if [ -f "/sys/$dir/product" ]; then
        DEVICE_MODEL=`cat /sys/$dir/product`
    fi
    if [ -f "/sys/$dir/speed" ]; then
        DEVICE_SPEED=`cat /sys/$dir/speed`
    fi
}
Hotplug_IsDeviceStorage()
{
    if [ ! -d "$USB_SILEX_DIR" ]; then
        return 0
    fi
    local devname=$1
    if [ -z "$devname" ]; then
        return 1
    fi
 
    Hotplug_GetDevpath "$devname"
    local usb_id=`echo $DEVICE_PATH | sed -n 's/.*\([1-9]-[1-9]:[0-9].[0-9]\).*/\1/p'`
    if [ -z "$usb_id" ]; then
        usb_id=`echo $DEVICE_PATH | sed -n 's/.*\([1-9]-[1-9].[1-9]\).*/\1/p'`
    fi
    ulog usb autodetect "$PID Hotplug_IsDeviceStorage - id: $usb_id"
    if [ -z "$usb_id" ]; then
        return 0
    fi
    ls -al "$USB_SILEX_DIR" | grep -q "$usb_id"
    if [ "$?" == "0" ]; then
        return 1
    fi
    return 0
}
USB1_ROOT_HUB="1-0:1.0"
USB2_ROOT_HUB="2-0:1.0"
USB3_ROOT_HUB="3-0:1.0"
USB_CTRL_1_1="1-1"  #USB2.0 in USB Port1 (Honda, Esprit, Lemans)
USB_CTRL_1_2="1-2"  #USB2.0 in USB Port2 (Honda, Esprit, Lemans)
USB_CTRL_2_1="2-1"  #USB3.0 in USB Port1 (Honda)
USB_CTRL_3_1="3-1"  #USB1.1 in USB Port1 (Honda)
USB_CTRL_3_2="3-2"  #USB1.1 in USB Port2 (Honda)
get_usb_port_from_multiple_host()
{
    [ -z "$1" ] && return
    ulog usb autodetect "$PID get_usb_port_from_multiple_host $1"
    get_syscfg_UsbPortCount
    if [ "$SYSCFG_UsbPortCount" = "2" ] ; then
        echo "$1" | grep -q "$USB1_ROOT_HUB"
        [ "0" = "$?" ] && USB_port="1" && return
        echo "$1" | grep -q "$USB2_ROOT_HUB"
        [ "0" = "$?" ] && USB_port="2" && return
        echo "$1" | grep -q "$USB3_ROOT_HUB"
        [ "0" = "$?" ] && USB_port="2" && return
        echo "$1" | grep -q "$USB_CTRL_1_1"
        [ "0" = "$?" ] && USB_port="1" && return
        echo "$1" | grep -q "$USB_CTRL_1_2"
        [ "0" = "$?" ] && USB_port="2" && return
        echo "$1" | grep -q "$USB_CTRL_2_1"
        [ "0" = "$?" ] && USB_port="1" && return
        echo "$1" | grep -q "$USB_CTRL_3_1"
        [ "0" = "$?" ] && USB_port="1" && return
        echo "$1" | grep -q "$USB_CTRL_3_2"
        [ "0" = "$?" ] && USB_port="2" && return
    else
        USB_port="1"
    fi
}
get_usb_port_from_single_host()
{
    [ -z "$1" ] && return
    ulog usb autodetect "$PID call get_usb_port_from_single_host $1"
    ls "$USB_DEVICES_DIR" | grep -q "[1-9]-[1-9].[1-9]$"
    [ "0" != "$?" ] && USB_port="1" && return
    echo "$1" | grep -q "[1-9]-[1-9].[1-9]$"
    if [ "0" = "$?" ] ; then
      USB_ID="$1"
    else
      USB_ID=`echo "$1" | awk -F "/" '{ for (i=1; i<=NF; i++) if ( $i ~ /[1-9]-[1-9].[1-9]$/ ) { print $i } }'`
    fi
    ulog usb autodetect "$PID single_usb_host(USB_ID)=$USB_ID"
    CUR_USB_PORT=`echo "$USB_ID" | cut -d '.' -f 2`
    ulog usb autodetect "$PID single_usb_host(CUR_USB_PORT)=$CUR_USB_PORT"
    [ "$CUR_USB_PORT" = "3" ] && USB_port="1" && return
    [ "$CUR_USB_PORT" = "4" ] && USB_port="2" && return
}
add_virtualusb_drivers()
{
    MODEL=`syscfg get device modelNumber`
    if [ -n "$MODEL" ] ; then 
      PRODUCT_STRING="product=\"${MODEL}\""
    fi
    MODULE_PATH=/lib/modules/`uname -r`/
    insmod ${MODULE_PATH}/sxuptp_wq.ko
    insmod ${MODULE_PATH}/sxuptp.ko
    insmod ${MODULE_PATH}/sxuptp_devfilter.ko
    echo -e "A, , , 0x07\nD, , , 0x08\nD, , , 0x09" | cat - > /proc/sxuptp/device_filter
    insmod ${MODULE_PATH}/sxuptp_driver.ko
    /usr/sbin/jcpd -f /etc/jcpd.conf
    ulog usb manager "add_virtualusb_drivers() $PRODUCT_STRING"
}
rm_virtualusb_drivers()
{
    killall -9 jcpd
    rmmod -f sxuptp_driver 2> /dev/null
    rmmod -f sxuptp_devfilter 2> /dev/null
    rmmod -f sxuptp 2> /dev/null
    rmmod -f sxuptp_wq 2> /dev/null
   
    ulog usb manager "remove_virtualusb_drivers()"
}

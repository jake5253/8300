#!/bin/sh

#------------------------------------------------------------------
# © 2013 Belkin International, Inc. and/or its affiliates. All rights reserved.
#------------------------------------------------------------------
source /etc/init.d/feedback_registration_functions.sh	 
###############################################################################
#	Feedback Events
#
#	You may add a new line for a new feedback event
#
# 	The format of each line of a feedback event string is:
# 	name_of_event | path/filename_of_handler ;\
#
#	Optionally if the handler takes a parameter
# 	name_of_event | path/filename_of_handler | parameter ;\
#
#
###############################################################################


FEEDBACK_EVENTS="\
	system_state-normal|/etc/led/solid.sh ;\
	system_state-error|/etc/led/pulsate.sh ;\
	system_state-heartbeat|/etc/led/pulsate.sh ;\
	phylink_wan_state|/etc/led/manage_wan_led.sh ;\
	wan-status|/etc/led/manage_wan_led.sh ;\
	fwupd-start|/etc/led/fwupd-start.sh ;\
	fwupd-success|/etc/led/fwupd-success.sh ;\
	fwupd-failed|/etc/led/fwupd-failed.sh ;\
	wps-running|/etc/led/pulsate_wps.sh ;\
	wps-success|/etc/led/solid_wps.sh ;\
	wps-failed|/etc/led/wps_failed.sh ;\
	wps-stopped|/etc/led/solid_wps.sh ;\
	led_ethernet_on|/etc/led/rear_all_default.sh ;\
	led_ethernet_off|/etc/led/rear_all_off.sh ;\
        usb_port_1_state|/etc/led/manage_usb1_led.sh ;\
        usb_port_1_umount|/etc/led/umount_usb1.sh ;\
        remove_usb_drives|/etc/led/umount_usb1.sh ;\
"


###############################################################################
#	No need to edit below
###############################################################################
	 	 
register_events_handler "$FEEDBACK_EVENTS"



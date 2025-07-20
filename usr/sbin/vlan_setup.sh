#!/bin/sh

#------------------------------------------------------------------
# © 2016 Belkin International, Inc. and/or its affiliates. All rights reserved.
#------------------------------------------------------------------

source /etc/init.d/interface_functions.sh
source /etc/init.d/ulog_functions.sh

vlan_id_10_to_16 ()
{
    vid=`printf '%03x\n' $1`
}

calculate_source_port ()
{
    val1=1
    val2=1
    i=1
    while [ $i -le $1 ]; do
        val1=`expr $val1 \* 2`
        i=$(($i+1))
    done
    i=1
    while [ $i -le $2 ]; do
        val2=`expr $val2 \* 2`
        i=$(($i+1))
    done
    val=`expr $val1 + $val2`
    val=`printf '%02x\n' $val`
    return $val
}

# get the relevant syscfg parameters
PARAM=`utctx_cmd get lan_ethernet_physical_ifnames lan_mac_addr wan_physical_ifname wan_mac_addr bridge_mode ipv6::passthrough_enable`
eval $PARAM

#WRAITH-128
ssdk_sh debug reg set 0x624 0x7f7f7f 4 > /dev/null 2>&1 #global forward control 1 reg

ssdk_sh debug reg set 0x620 0x1004f0 4 > /dev/null 2>&1 #global forward control 0 reg
ssdk_sh debug reg set 0x200 0x31 4 > /dev/null 2>&1 # drop frame when IPv4 header length check fails
ssdk_sh debug reg set 0x204 0x5800 4 > /dev/null 2>&1 # drop the ICMP checksum error
acl_rule_index=1
acl_rule_index=`printf '%02x\n' $acl_rule_index`
if [ "$SYSCFG_bridge_mode" != "0" ] ; then
    #bridge mode
    #Enable bridge mode, and packets from port 5 is sent to eth1, not eth0.
    echo 1 > /proc/sys/net/edma/bridge_mode

    #port-based VLAN. port 0,1,2,3,4,5 in the same VLAN.
    ssdk_sh vlan entry flush 0 > /dev/null 2>&1
    ssdk_sh vlan entry create 1 > /dev/null 2>&1
    ssdk_sh vlan member add 1 0 tagged > /dev/null 2>&1
    ssdk_sh vlan member add 1 1 untagged > /dev/null 2>&1
    ssdk_sh vlan member add 1 2 untagged > /dev/null 2>&1
    ssdk_sh vlan member add 1 3 untagged > /dev/null 2>&1
    ssdk_sh vlan member add 1 4 untagged > /dev/null 2>&1
    ssdk_sh vlan member add 1 5 untagged > /dev/null 2>&1
    #VLAN_CTRL0 b31:29 ING_PORT_CPRI
    #b27:16 PORT_DEFAULT_CVID
    #b15:13 ING_PORT_SPRI
    #B11:0 PORT_DEFAULT_SVID
    ssdk_sh debug reg set 0x420 0x10001 4 > /dev/null 2>&1 #p0
    ssdk_sh debug reg set 0x428 0x10001 4 > /dev/null 2>&1 #p1
    ssdk_sh debug reg set 0x430 0x10001 4 > /dev/null 2>&1 #p2
    ssdk_sh debug reg set 0x438 0x10001 4 > /dev/null 2>&1 #p3
    ssdk_sh debug reg set 0x440 0x10001 4 > /dev/null 2>&1 #p4
    ssdk_sh debug reg set 0x448 0x10001 4 > /dev/null 2>&1 #p5
    #VLAN_CTRL1 b13:12 EG_VLAN_MODE 01=untagged, 10=tagged
    #b3:2 ING_VLAN_MODE 01=tagged, 10=untagged
    ssdk_sh debug reg set 0x424 0x1040 4 > /dev/null 2>&1 #p0
    ssdk_sh debug reg set 0x42c 0x1040 4 > /dev/null 2>&1 #p1
    ssdk_sh debug reg set 0x434 0x1040 4 > /dev/null 2>&1 #p2
    ssdk_sh debug reg set 0x43c 0x1040 4 > /dev/null 2>&1 #p3
    ssdk_sh debug reg set 0x444 0x1040 4 > /dev/null 2>&1 #p4
    ssdk_sh debug reg set 0x44c 0x1040 4 > /dev/null 2>&1 #p5
    #LOOKUP_CTRL b20 1=enable hardware learn new MAC address into ARL table
    #b18:16 100=forward mode
    ssdk_sh debug reg set 0x660 0x14033e 4 > /dev/null 2>&1 #p0
    ssdk_sh debug reg set 0x66c 0x14033d 4 > /dev/null 2>&1 #p1
    ssdk_sh debug reg set 0x678 0x14033b 4 > /dev/null 2>&1 #p2
    ssdk_sh debug reg set 0x684 0x140337 4 > /dev/null 2>&1 #p3
    ssdk_sh debug reg set 0x690 0x14032f 4 > /dev/null 2>&1 #p4
    ssdk_sh debug reg set 0x69c 0x14031f 4 > /dev/null 2>&1 #p5 
else
    #router mode
    echo 0 > /proc/sys/net/edma/bridge_mode

    if [ "`syscfg get vlan_tagging::enabled`" = "0" ] ; then
        #set 802.1q mode and port-based VLAN member
        ssdk_sh debug reg set 0x660 0x14033e 4 > /dev/null 2>&1 #p0
        ssdk_sh debug reg set 0x66c 0x14031d 4 > /dev/null 2>&1 #p1
        ssdk_sh debug reg set 0x678 0x14031b 4 > /dev/null 2>&1 #p2
        ssdk_sh debug reg set 0x684 0x140317 4 > /dev/null 2>&1 #p3
        ssdk_sh debug reg set 0x690 0x14030f 4 > /dev/null 2>&1 #p4
        ssdk_sh debug reg set 0x69c 0x140301 4 > /dev/null 2>&1 #p5

        #set vlan
        ssdk_sh vlan entry create 1 > /dev/null 2>&1
        ssdk_sh vlan member add 1 0 tagged > /dev/null 2>&1
        ssdk_sh vlan member add 1 1 untagged > /dev/null 2>&1
        ssdk_sh vlan member add 1 2 untagged > /dev/null 2>&1
        ssdk_sh vlan member add 1 3 untagged > /dev/null 2>&1
        ssdk_sh vlan member add 1 4 untagged > /dev/null 2>&1
        ssdk_sh vlan entry create 2 > /dev/null 2>&1
        ssdk_sh vlan member add 2 0 tagged > /dev/null 2>&1
        ssdk_sh vlan member add 2 5 untagged > /dev/null 2>&1

        #set port PVID
        ssdk_sh portVlan defaultCVid set 0 0 > /dev/null 2>&1
        ssdk_sh portVlan defaultCVid set 1 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultCVid set 2 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultCVid set 3 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultCVid set 4 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultCVid set 5 2 > /dev/null 2>&1

        ssdk_sh portVlan defaultSVid set 0 0 > /dev/null 2>&1
        ssdk_sh portVlan defaultSVid set 1 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultSVid set 2 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultSVid set 3 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultSVid set 4 1 > /dev/null 2>&1
        ssdk_sh portVlan defaultSVid set 5 2 > /dev/null 2>&1
    else
        wan_vid=`syscfg get wan_1::vlan_id`
        echo $wan_vid > /proc/sys/net/edma/default_wan_tag
        vlan1_ports="0 1 2 3 4"
        vlan_no=3
        ssdk_sh vlan entry flush 0 > /dev/null 2>&1
        wan_port=`syscfg get switch::router_2::port_numbers`
        for lan_no in 2 3 ; do
            c=1
            count=`syscfg get lan_$lan_no::vlan_count`
            while [ $c -le $count ] ; do
                vid=`syscfg get lan_$lan_no::vlan_id_$c`
                vid_hex=`printf '%03x\n' $vid`
                port_numbers=`syscfg get lan_$lan_no::port_numbers_$c`
                prio=`syscfg get lan_$lan_no::prio_$c`
                prio=`expr $prio \* 2`
                prio=`printf '%x\n' $prio`
                ports=""
                ssdk_sh vlan entry create $vid > /dev/null 2>&1
                voip_iptv_ports="3 4" # actually this is the index, so same for wraith and macan. below different registers are used for wraith and macan.
                for port_index in $voip_iptv_ports ; do
                    port_tagging=$(echo $port_numbers | cut -f $port_index -d ' ')
                   
                    if [ "$port_tagging" != "3" ] ; then
                        port_no=$(syscfg get switch::router_1::port_numbers | cut -f $port_index -d ' ')
                        if [ "$port_tagging" = "2" ] ; then
                            ssdk_sh vlan member add $vid $port_no tagged > /dev/null 2>&1
                        else
                            ssdk_sh vlan member add $vid $port_no untagged > /dev/null 2>&1
                        fi
                        reg=`printf '%d\n' 0x420`
                        reg_dec=`expr $reg + 8 \* $port_no`
                        reg=`printf '%03x\n' $reg_dec`
                        ssdk_sh debug reg set 0x$reg 0x${prio}${vid_hex}${prio}${vid_hex} 4 > /dev/null 2>&1
                         
                        reg_dec=`expr $reg_dec + 4`
                        reg=`printf '%03x\n' $reg_dec`
                        if [ "$port_tagging" = "2" ] ; then
                            ssdk_sh debug reg set 0x$reg 0x2044 4 > /dev/null 2>&1
                        else
                            ssdk_sh debug reg set 0x$reg 0x1048 4 > /dev/null 2>&1
                        fi
                        reg=`printf '%d\n' 0x660`
                        reg_dec=`expr $reg + 12 \* $port_no`
                        reg=`printf '%03x\n' $reg_dec`
                        ssdk_sh debug reg set 0x$reg 0x00140300 4 > /dev/null 2>&1
                        vlan1_ports=`echo $vlan1_ports | sed 's/'$port_no'//'`
                        prev_lan_no=`expr $lan_no - 1`
                        prev_tagging=$(syscfg get lan_${prev_lan_no}::port_numbers_$c | cut -f $port_index -d ' ')
                        if [ "$prio" != "0" ] && [ "$prev_tagging" = "3" -o "`syscfg get lan_${prev_lan_no}::prio_$c`" != "`syscfg get lan_${lan_no}::prio_$c`" ] ; then
                            ssdk_sh debug reg set 0x30 0x80000703 4 > /dev/null 2>&1 # bit1-ACL_EN, MIB_EN
                            #################################### ACL Rule-1 ##################################
                            ############ change c-priority #########################
                            ########### Add MAC rule on Port0 & Port1 ###########
                            # MAC Rule: see table 3.2.1.3(MAC Rule) and mapping to reg0x0404 ~ reg0x0414
                            ssdk_sh debug reg set 0x404 0x00000000 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x408 0x00000000 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x410 0x00000${vid_hex} 4 > /dev/null 2>&1
                            calculate_source_port $port_no $wan_port
                            ret=$?
                            ssdk_sh debug reg set 0x414 0x000000$ret 4 > /dev/null 2>&1 # Source Port
                            ssdk_sh debug reg set 0x400 0x800000$acl_rule_index 4 > /dev/null 2>&1 # ACL_Busy, Write command, Rule and Index to ind-1
                            ########### Add MAC mask ###########
                            # MAC Mask: see table 3.2.1.3(MAC Rule Mask) and mapping to reg0x0404 ~ reg0x0414
                            ssdk_sh debug reg set 0x404 0x00000000 4 > /dev/null 2>&1 # DA mask
                            ssdk_sh debug reg set 0x408 0x00000000 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x410 0x00000fff 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x414 0x000000f9 4 > /dev/null 2>&1 # start & end , MAC rule type, vid-mask MUST be 1
                            ssdk_sh debug reg set 0x400 0x800001$acl_rule_index 4 > /dev/null 2>&1 # ACL_Busy, Write command, Mask and Index to ind-1
                            ########### Add MAC result ###########
                            # MAC Result: see table 3.2.1.2(Rule Result) and mapping to reg0x0404 ~ reg0x0414
                            ssdk_sh debug reg set 0x404 0x${prio}0000000 4 > /dev/null 2>&1 # Ctag-pri bits [31:29]
                            ssdk_sh debug reg set 0x408 0x00000200 4 > /dev/null 2>&1 # b41=1, ctag_pri_remap_en
                            ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1 #forward
                            #debug reg set 0x40c 0x000001C0 4 #dropped
                            ssdk_sh debug reg set 0x410 0x00000000 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x414 0x00000000 4 > /dev/null 2>&1
                            ssdk_sh debug reg set 0x400 0x800002$acl_rule_index 4 > /dev/null 2>&1 # ACL_Busy, Write command, Result and Index to ind-1
                            acl_rule_index=`expr $acl_rule_index + 1`
                            acl_rule_index=`printf '%02x\n' $acl_rule_index`
                        fi
                    fi
                done
                ssdk_sh vlan member add $vid $wan_port tagged > /dev/null 2>&1
                c=`expr $c + 1`
                vlan_no=`expr $vlan_no + 1`
            done
        done
        ssdk_sh vlan entry create 1 > /dev/null 2>&1
        for port in $vlan1_ports ; do
            reg_dec=`printf '%d\n' 0x420`
            reg_dec=`expr $reg_dec + 8 \* $port`
            reg=`printf '%03x\n' $reg_dec`
            if [ "$port" = "0" ] ; then
                ssdk_sh vlan member add 1 0 tagged > /dev/null 2>&1
            else
                ssdk_sh vlan member add 1 $port untagged > /dev/null 2>&1
            fi
            ssdk_sh debug reg set 0x$reg 0x10001 4 > /dev/null 2>&1
            reg_dec=`expr $reg_dec + 4`
            reg=`printf '%03x\n' $reg_dec`
            ssdk_sh debug reg set 0x$reg 0x1048 4 > /dev/null 2>&1
        done
        #WRAITH-281
        echo "$vlan1_ports" | grep -qri 3
        port3_in=$?
        echo "$vlan1_ports" | grep -qri 4
        port4_in=$?
        port1=`printf '%d\n' 0x05`
        port2=`printf '%d\n' 0x03`
        port3=`printf '%d\n' 0x07`
        port4=`printf '%d\n' 0x07`
        port0=`printf '%d\n' 0x06`
        if [ $port3_in = 0 ] ; then #p3 exists in vlan1
            port1=`expr $port1 + 8`
            port2=`expr $port2 + 8`
            if [ $port4_in = 0 ] ; then
                port4=`expr $port4 + 8`
            fi
            port0=`expr $port0 + 8`
        fi
        if [ $port4_in = 0 ] ; then
            port1=`expr $port1 + 16`
            port2=`expr $port2 + 16`
            if [ $port3_in = 0 ] ; then
                port3=`expr $port3 + 16`
            fi
            port0=`expr $port0 + 16`
        fi
        port1=`printf '%02x\n' $port1`
        port2=`printf '%02x\n' $port2`
        port3=`printf '%02x\n' $port3`
        port4=`printf '%02x\n' $port4`
        port0=`printf '%02x\n' $port0`
        #LOOKUP_CTRL b20 1=enable hardware learn new MAC address into ARL table
        #b18:16 100=forward mode
        #b9:8 00=802.1q disable, 01=fallback, 10=check, 11=secure
        #b6:0 port-based VLAN member
        ssdk_sh debug reg set 0x66c 0x1400$port1 4 > /dev/null 2>&1 #p1
        ssdk_sh debug reg set 0x678 0x1400$port2 4 > /dev/null 2>&1 #p2
        if [ $port3_in = 0 ] ; then
            ssdk_sh debug reg set 0x684 0x1400$port3 4 > /dev/null 2>&1 #p3
        fi
        if [ $port4_in = 0 ] ; then
            ssdk_sh debug reg set 0x690 0x1400$port4 4 > /dev/null 2>&1 #p4
        fi
        ssdk_sh debug reg set 0x660 0x1401$port0 4 > /dev/null 2>&1 #p0 enable 802.1q, very important!!!
        wan_vid_hex=`printf '%03x\n' $wan_vid`
        prio=`syscfg get wan_1::prio`
        prio=`expr $prio \* 2`
        prio=`printf '%x\n' $prio`
        ssdk_sh vlan entry create $wan_vid > /dev/null 2>&1
        ssdk_sh vlan member add $wan_vid 0 tagged > /dev/null 2>&1
        reg_dec=`printf '%d\n' 0x420`
        reg_dec=`expr $reg_dec + 8 \* $wan_port`
        reg=`printf '%03x\n' $reg_dec`
        ssdk_sh debug reg set 0x$reg 0x0{$wan_vid_hex}0{$wan_vid_hex} 4 > /dev/null 2>&1 #VLAN_CTRL0; priority=0, default-cvid=2
        if [ "`syscfg get switch::router_2::port_tagging`" = "u" ] ; then
            ssdk_sh vlan member add $wan_vid 5 untagged > /dev/null 2>&1
        else
            ssdk_sh vlan member add $wan_vid 5 tagged > /dev/null 2>&1
            reg_dec=`expr $reg_dec + 4`
            reg=`printf '%03x\n' $reg_dec` 
            ssdk_sh debug reg set 0x$reg 0x2044 4 > /dev/null 2>&1 #VLAN_CTRL1; b3:2=01,only tagged in; b13:12=10, tagged out
        fi
        reg_dec=`printf '%d\n' 0x660`
        reg_dec=`expr $reg_dec + 12 \* $wan_port`
        reg=`printf '%03x\n' $reg_dec`
        ssdk_sh debug reg set 0x$reg 0x140101 4 > /dev/null 2>&1 #LOOKUP_CTRL
        ssdk_sh debug reg set 0x420 0x${prio}${wan_vid_hex}${prio}${wan_vid_hex} 4 > /dev/null 2>&1 #p0, VLAN_CTRL0; priority=0, default-cvid=0xa=10
        ssdk_sh debug reg set 0x424 0x2040 4 > /dev/null 2>&1 #p0, VLAN_CTRL1; b3:2=10,only untagged in; b13:12=01, untagged out
        ssdk_sh debug reg set 0x30 0x80000703 4 > /dev/null 2>&1 # bit1-ACL_EN, MIB_EN
        # Using ACL to set wan vlan priority
        ########### Add MAC pattern ###########
        ssdk_sh debug reg set 0x404 0x00000000 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x408 0x00000000 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x410 0x00000${wan_vid_hex} 4 > /dev/null 2>&1
        calculate_source_port 0 $wan_port
        ret=$?
        ssdk_sh debug reg set 0x414 0x000000$ret 4 > /dev/null 2>&1 # Source Port
        ssdk_sh debug reg set 0x400 0x800000$acl_rule_index 4 > /dev/null 2>&1 # ACL_Busy, Write command, Rule and Index to ind-1
        ########### Add MAC mask ###########
        ssdk_sh debug reg set 0x404 0x00000000 4 > /dev/null 2>&1 # DA mask
        ssdk_sh debug reg set 0x408 0x00000000 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x410 0x00000fff 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x414 0x000000f9 4 > /dev/null 2>&1 # start & end , MAC rule type, vid-mask MUST be 1
        ssdk_sh debug reg set 0x400 0x800001$acl_rule_index 4 > /dev/null 2>&1 # ACL_Busy, Write command, Mask and Index to ind-1
        ########### Add MAC action ###########
        ssdk_sh debug reg set 0x404 0x${prio}0000000 4 > /dev/null 2>&1 # Ctag-pri bits [31:29]
        ssdk_sh debug reg set 0x408 0x00000200 4 > /dev/null 2>&1 # b41=1, ctag_pri_remap_en
        ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1 #forward
        ssdk_sh debug reg set 0x410 0x00000000 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x414 0x00000000 4 > /dev/null 2>&1
        ssdk_sh debug reg set 0x400 0x800002$acl_rule_index 4 > /dev/null 2>&1 # ACL_Busy, Write command, Result and Index to ind-1
        acl_rule_index=`expr $acl_rule_index + 1`
        acl_rule_index=`printf '%02x\n' $acl_rule_index`
    fi

fi
ip link set $SYSCFG_lan_ethernet_physical_ifnames down
ip link set $SYSCFG_lan_ethernet_physical_ifnames addr $SYSCFG_lan_mac_addr
ip link set $SYSCFG_lan_ethernet_physical_ifnames up

if [ $SYSCFG_bridge_mode = "0" ] ; then
    ip link set $SYSCFG_wan_physical_ifname down
    ip link set $SYSCFG_wan_physical_ifname addr $SYSCFG_wan_mac_addr
    ip link set $SYSCFG_wan_physical_ifname up
fi

if [ "$SYSCFG_ipv6_passthrough_enable" = "1" ] ; then
    echo 1 > /proc/sys/net/edma/ipv6_passthru_mode
    ssdk_sh debug reg set 0x30 0x80000703 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x610 0x001b5560 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x614 0x80030002 4 > /dev/null 2>&1

    ssdk_sh debug reg set 0x404 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x408 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x410 0x86dd0000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x414 0x0000003f 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x400 0x800000$acl_rule_index 4 > /dev/null 2>&1

    ssdk_sh debug reg set 0x404 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x408 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x410 0xffff0000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x414 0x000000c9 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x400 0x800001$acl_rule_index 4 > /dev/null 2>&1

    ssdk_sh debug reg set 0x404 0x00030000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x408 0x00002000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x40c 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x410 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x414 0x00000000 4 > /dev/null 2>&1
    ssdk_sh debug reg set 0x400 0x800002$acl_rule_index 4 > /dev/null 2>&1

    ssdk_sh debug reg set 0x660 0x14013e 4 > /dev/null 2>&1 #p0
    ssdk_sh debug reg set 0x66c 0x14013d 4 > /dev/null 2>&1 #p1
    ssdk_sh debug reg set 0x678 0x14013b 4 > /dev/null 2>&1 #p2
    ssdk_sh debug reg set 0x684 0x140137 4 > /dev/null 2>&1 #p3
    ssdk_sh debug reg set 0x690 0x14012f 4 > /dev/null 2>&1 #p4
    ssdk_sh debug reg set 0x69c 0x14011f 4 > /dev/null 2>&1 #p5
fi

#there are some garbage fdb entries produced during switch initialization, flush them
ssdk_sh fdb entry flush 0 > /dev/null 2>&1
ulog vlan tagging "ACL has $acl_rule_index rules"

#set igmp snooping configurations
ssdk_sh igmp portJoin set 1 enable > /dev/null 2>&1
ssdk_sh igmp portJoin set 2 enable > /dev/null 2>&1
ssdk_sh igmp portJoin set 3 enable > /dev/null 2>&1
ssdk_sh igmp portJoin set 4 enable > /dev/null 2>&1
ssdk_sh igmp portLeave set 1 enable > /dev/null 2>&1
ssdk_sh igmp portLeave set 2 enable > /dev/null 2>&1
ssdk_sh igmp portLeave set 3 enable > /dev/null 2>&1
ssdk_sh igmp portLeave set 4 enable > /dev/null 2>&1
ssdk_sh igmp createStatus set enable > /dev/null 2>&1
ssdk_sh igmp version3 set enable > /dev/null 2>&1
if [ "$SYSCFG_bridge_mode" != "0" ]; then
    ssdk_sh igmp portJoin set 0 enable > /dev/null 2>&1
    ssdk_sh igmp portLeave set 0 enable > /dev/null 2>&1
    ssdk_sh igmp portJoin set 5 enable > /dev/null 2>&1
    ssdk_sh igmp portLeave set 5 enable > /dev/null 2>&1
    ssdk_sh igmp rp set 0x3f > /dev/null 2>&1
else
    ssdk_sh igmp portJoin set 0 disable > /dev/null 2>&1
    ssdk_sh igmp portLeave set 0 disable > /dev/null 2>&1
    ssdk_sh igmp portJoin set 5 disable > /dev/null 2>&1
    ssdk_sh igmp portLeave set 5 disable > /dev/null 2>&1
    ssdk_sh igmp rp set 0x1f > /dev/null 2>&1
fi

#!/bin/sh
HISTORY_DATA="/tmp/var/config/GetWifiInfoData_LegacyClient"
TMP_FILEPREFIX="/tmp/.GetWifiINfoTMp"
FILEPREFIX_IWLIST="${TMP_FILEPREFIX}_iwlistResult"
FILEPREFIX_ACSREPORT="${TMP_FILEPREFIX}_acsReport"
FILEPREFIX_TMPDATA="${TMP_FILEPREFIX}_tmpData"
GLOBAL_CMD_TIMEOUT=60
PrintLog()
{
echo "${PROCEED_NAME}: $1" >&2
}
PHYSICAL_IF_LIST=`syscfg get lan_wl_physical_ifnames`
ShowBasicInfo()
{
echo "var BasicInfo={"
echo "\"title\": \"Basic Info\","
echo "\"description\": \"basic information about platform\","
echo "\"data\": [{"
echo "	\"vendor\": \"${VENDOR}\","
echo "	\"CountryCode\": \"`syscfg get device::cert_region`\","
echo "	\"WifiDriverVer\": \"\""
echo "}]"
echo "};"
}
APNUM_SAMECHANNEL_WL0=0
APNUM_SAMECHANNEL_WL1=0
showCAInfoForMyChannel()
{
PHYSICAL_NUM=`syscfg get lan_wl_physical_ifnames | awk '{print NF}'`
for PHY_IF in $PHYSICAL_IF_LIST; do
	if [ ! -f "${FILEPREFIX_ACSREPORT}_${PHY_IF}" ];then
		CHANNEL=`iwlist ${PHY_IF} channel | sed 's/)//'|awk  '/Fre/ {print $5}'`
		iwpriv ${PHY_IF} acsmindwell 1000 && iwpriv ${PHY_IF} acsmaxdwell 1500
		wifitool ${PHY_IF} setchanlist ${CHANNEL}
		iwpriv ${PHY_IF} acsreport 1
		sleep 2
		wifitool ${PHY_IF} acsreport | grep "([ ]*${CHANNEL})" > "${FILEPREFIX_ACSREPORT}_${PHY_IF}"
	fi
done
FLAG2G_DONE="0"
FLAG5G_DONE="0"
CHANNEL2G_NUM="0"
CHANNEL5G_NUM="0"
for PHY_IF in $PHYSICAL_IF_LIST; do
	CHANNEL_NUM=0
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
                if [ $FLAG2G_DONE = "0" ];then
			FLAG2G_DONE="1"
		else
			continue
		fi
		CHANNEL2G_NUM=`iwlist ${PHY_IF} channel | sed '/Current Frequency/d' | grep Channel | wc -l`
		CHANNEL_NUM=${CHANNEL2G_NUM}
	else
		RADIO_TYPE="5GHz"
                if [ $FLAG5G_DONE = "0" ];then
			FLAG5G_DONE="1"
		else
			continue
		fi
		CHANNEL5G_NUM=`iwlist ${PHY_IF} channel | sed '/Current Frequency/d' | grep Channel | wc -l`
		CHANNEL_NUM=${CHANNEL5G_NUM}
	fi
	INDEX=1
	CHANNEL_LIST=""
	echo "CHANNEL_NUM=$CHANNEL_NUM"
	while [[ ${INDEX} -le ${CHANNEL_NUM} ]] ; do
		CHANNEL=`iwlist ${PHY_IF} channel | sed '/Current Frequency/d' |grep Channel | sed -n "${INDEX}p" | awk '{print $2}'`
		CHANNEL_LIST="${CHANNEL_LIST} ${CHANNEL}"
		INDEX=`expr ${INDEX} + 1`
	done
	echo "CHANNEL_LIST=$CHANNEL_LIST"
	if [ ! -f "${FILEPREFIX_ACSREPORT}_${PHY_IF}" ];then
		iwpriv "${PHY_IF}" acsmindwell 1000 && iwpriv "${PHY_IF}" acsmaxdwell 1500
		wifitool "${PHY_IF}" setchanlist "${CHANNEL_LIST}"
		iwpriv "${PHY_IF}" acsreport 1
		NUMBER=0
		while [[ ${NUMBER} -lt ${CHANNEL_NUM} ]] ; do
			NUMBER=`wifitool "${PHY_IF}" acsreport | grep ") " | wc -l`
		done
		wifitool "${PHY_IF}" acsreport | grep ") " | tr -s " "  > "${FILEPREFIX_ACSREPORT}_${PHY_IF}"
	fi
done
echo "var CAInfo={"
echo "\"title\": \"channel analysis\","
echo "\"description\": \"the information about channel analysis\","
echo "\"band\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
echo "  {\"name\": \"${PHY_IF}\","
echo "  \"type\":\"${RADIO_TYPE}\","
echo "  \"band\": \"`syscfg get ${WL_SYSCFG}_radio_band`\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr ${INDEX} + 1`
done
echo "],"
echo "\"rssi\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
echo " {\"name\": \"${PHY_IF}\","
echo "  \"type\":\"${RADIO_TYPE}\","
	RSSI=`cat "${FILEPREFIX_ACSREPORT}_${PHY_IF}" | awk -F')' '{print $2}' | awk '{print $3}' | sed "s/ //g"`
echo "  \"rssi\": \"${RSSI}\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr ${INDEX} + 1`
done
echo "],"
echo "\"noise\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
echo "	{\"name\": \"${PHY_IF}\","
echo "	\"type\":\"${RADIO_TYPE}\","
	NOISE=`cat "${FILEPREFIX_ACSREPORT}_${PHY_IF}" | awk -F')' '{print $2}' | awk '{print $4}'| sed "s/ //g"`
echo "	\"noise\": \"${NOISE}\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr ${INDEX} + 1`
done
echo "],"
echo "\"power\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
echo "	{\"name\": \"${PHY_IF}\","
echo "	\"type\":\"${RADIO_TYPE}\","
	RSSI=`cat "${FILEPREFIX_ACSREPORT}_${PHY_IF}" | awk -F')' '{print $2}' | awk '{print $3}' | sed "s/ //g" `
	NOISE=`cat "${FILEPREFIX_ACSREPORT}_${PHY_IF}" | awk -F')' '{print $2}' | awk '{print $4}' | sed "s/ //g"`
	POWER=`expr ${RSSI} + ${NOISE} `
echo "	\"power\": \"${POWER}\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr ${INDEX} + 1`
done
echo "],"
echo "\"ap\": ["
for PHY_IF in $PHYSICAL_IF_LIST; do
	if [ ! -f "${FILEPREFIX_IWLIST}_${PHY_IF}" ];then
	    iwlist ${PHY_IF} scan > ${FILEPREFIX_IWLIST}_${PHY_IF}
	fi
done
FIRST_INTERFACE=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	FIRSTDONE=0
	APNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | wc -l`
	if [ "${APNUM}" = "0" ] ; then
		continue
	fi
	MYCHANNEL=`iwlist ${PHY_IF} channel | sed 's/)//'|awk  '/Fre/ {print $5}'`
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
	if [ "$FIRST_INTERFACE" = "1" ];then
		FIRST_INTERFACE=0
	else
		echo "  ,"
	fi
echo "  {\"channel\": \"${MYCHANNEL}\","
echo "   \"type\": \"${RADIO_TYPE}\","
echo "   \"data\":["
	INDEX=1
	NUMBER=0
	while [ ${INDEX} -le ${APNUM} ]
	do
		RESULTFILE="${FILEPREFIX_IWLIST}_${PHY_IF}_RESULT_"
		if [  ${INDEX} -eq ${APNUM} ] ; then
			STARTROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${INDEX}p`
			cat ${FILEPREFIX_IWLIST}_${PHY_IF} | sed -n "${STARTROWNUM},$ p" > ${RESULTFILE}
		else
			
			STARTROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${INDEX}p`
			ENDROWNUM=`expr ${INDEX} + 1`
			ENDROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${ENDROWNUM}p`
			ENDROWNUM=`expr ${ENDROWNUM} - 1`
			cat ${FILEPREFIX_IWLIST}_${PHY_IF} | sed -n ${STARTROWNUM},${ENDROWNUM}p > ${RESULTFILE}
		fi
		
		
		CHANNEL=`cat ${RESULTFILE} | grep 'Frequency:' | awk -F 'Channel ' '{print $2}' | sed 's/)//'`
		if [ "$CHANNEL" != "$MYCHANNEL" ];then
		    INDEX=`expr ${INDEX} + 1`
		    continue
		fi
		SSID=`cat ${RESULTFILE} | grep 'ESSID:' | awk -F ':' '{print $2}'`
		if [ "$SSID" = '""' ]; then
			INDEX=`expr $INDEX + 1`
			continue
		fi
		if [ "$FIRSTDONE" = "1" ]; then
		    echo "  ,"
		fi
		echo "	{\"ssid\": ${SSID},"
		echo "	 \"bssid\": \"`cat ${RESULTFILE} | grep ' Address: ' | awk -F ': ' '{print $2}'`\","
		echo "	 \"type\": \"${RADIO_TYPE}\","
		echo "	 \"channel\": \"`cat ${RESULTFILE} | grep 'Frequency:' | awk -F 'Channel ' '{print $2}' | sed 's/)//'`\","
		echo "	 \"rssi\": \"`cat ${RESULTFILE} | grep "Signal level=" | awk -F '=-' '{print $2}' | awk '{print $1}'`\","
		if [ -n "`cat ${RESULTFILE} | grep 'Encryption key:on'`" ] ; then
		echo "	 \"security\": \"`cat ${RESULTFILE} | grep "IE:" | sed -n 1p | awk -F '/' '{print $2}' | awk '{print $1}'`\","
		elif [ -n "`cat ${RESULTFILE} | grep 'Encryption key:off'`"  ] ; then
		echo "	 \"security\": \"off\","
		else
		echo "	 \"security\": \"\","
		fi
		echo "	 \"vendor\": \"\","
		MODE=`cat ${RESULTFILE}| grep "phy_mode=" | awk -F 'phy_mode=' '{print $2}'`
		echo "	 \"bandwidth\": \"`ModeToBandwidth ${MODE} | awk '{print $1}'`\","
		echo "	 \"mode\": \"${MODE}\"}"
		if [ "$FIRSTDONE" = "0" ]; then
			FIRSTDONE=1
		fi
		INDEX=`expr ${INDEX} + 1`
		NUMBER=`expr ${NUMBER} + 1`
		if [ "$WL_SYSCFG" = "wl0" ];then
			APNUM_SAMECHANNEL_WL0=`expr ${APNUM_SAMECHANNEL_WL0} + 1`
		elif [ "$WL_SYSCFG" = "wl1" ]; then
			APNUM_SAMECHANNEL_WL1=`expr ${APNUM_SAMECHANNEL_WL1} + 1`
		fi
	done
echo "  ],"
echo "  \"number\": \"${NUMBER}\"}"
done
echo "],"
echo "\"txpower\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
echo "	{\"name\": \"${PHY_IF}\","
echo "	\"type\":\"${RADIO_TYPE}\","
echo "	\"txpower\": \"`iwlist ${PHY_IF} txpower | grep "Current Tx-Power" | awk -F ':' '{print $2}' | awk '{print $1}'`\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr ${INDEX} + 1`
done
echo "]"
echo "};" 
}
showCAInfoForAllChannel()
{
PHYSICAL_NUM=`syscfg get lan_wl_physical_ifnames | awk '{print NF}'`
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	CHANNEL_LIST=`syscfg get ${WL_SYSCFG}_available_channels | sed 's/,/ /g' `
	CHANNEL_NUM=`syscfg get ${WL_SYSCFG}_available_channels | sed 's/,/\n/g' | wc -l `
	if [ ! -f "${FILEPREFIX_ACSREPORT}_${PHY_IF}" ];then
		iwpriv ${PHY_IF} acsmindwell 1000 && iwpriv ${PHY_IF} acsmaxdwell 1500
		wifitool ${PHY_IF} setchanlist ${CHANNEL_LIST}
		iwpriv ${PHY_IF} acsreport 1
		INDEX=1
		while true ;do
		    sleep 1
		    INDEX=`expr ${INDEX} + 1`
		    NUMBER=`wifitool ${PHY_IF} acsreport | grep ") " | wc -l`
		    if [[ ${NUMBER} -ge ${CHANNEL_NUM}  ]]; then
			break
		    fi
		    if [[ $INDEX -ge $GLOBAL_CMD_TIMEOUT ]] ; then
			PrintLog "showCAInfoForAllChannel failed to get result, time out"
			return
		    fi
		done
		wifitool ${PHY_IF} acsreport | grep ") " | tr -s " "  > ${FILEPREFIX_ACSREPORT}_${PHY_IF}
	fi
done
echo "var CAInfo={"
echo "\"title\": \"channel analysis\","
echo "\"description\": \"the information about channel analysis\","
echo "\"myband\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
echo "  {\"name\": \"${PHY_IF}\","
echo "  \"type\":\"${RADIO_TYPE}\","
echo "  \"band\": \"`syscfg get ${WL_SYSCFG}_radio_band`\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr ${INDEX} + 1`
done
echo "],"
echo "\"mychannel\": ["
FIRST_INTERFACE=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	MYCHANNEL=`iwlist ${PHY_IF} channel | sed 's/)//'|awk  '/Current Frequency/ {print $5}'`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
	if [ "$FIRST_INTERFACE" = "1" ];then
		FIRST_INTERFACE=0
	else
echo "  ,"
	fi
echo	"  {\"interface\": \"${PHY_IF}\","
echo	"   \"type\": \"${RADIO_TYPE}\","
echo	"   \"data\": ["
echo 	"      {\"channel\": \"`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF} | grep "([ ]*${MYCHANNEL})" | awk -F')' '{print $1}' | awk -F '(' '{print $2}' | sed 's/ //g' `\","
echo 	"       \"bssnumber\": \"`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF}  | grep "([ ]*${MYCHANNEL})"  | awk -F')' '{print $2}' | awk '{print $1}'`\","
	MAXRSSI=`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF} | grep "([ ]*${MYCHANNEL})"  | awk -F')' '{print $2}' | awk '{print $3}' | sed "s/ //g" `
	NOISE=`cat "${FILEPREFIX_ACSREPORT}_${PHY_IF}" | grep "([ ]*${MYCHANNEL})"  | awk -F')' '{print $2}' | awk '{print $4}' | sed "s/ //g"`
	POWER=`expr ${MAXRSSI} + ${NOISE} `
echo 	"       \"minrssi\": \"`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF}  | grep "([ ]*${MYCHANNEL})"  | awk -F')' '{print $2}' | awk '{print $2}'`\","
echo 	"       \"maxrssi\": \"${MAXRSSI}\","
echo 	"       \"noise\": \"${NOISE}\","
echo	"       \"power\": \"${POWER}\","
echo 	"       \"load\": \"`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF}  | grep "([ ]*${MYCHANNEL})"  | awk -F')' '{print $2}' | awk '{print $5}'`\"}"
echo    "     ]"
echo	"  }"
done
echo "],"
echo "\"channels\": ["
FIRST_INTERFACE=1
echo > ${FILEPREFIX_TMPDATA}
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
	if [ "$FIRST_INTERFACE" = "1" ];then
		FIRST_INTERFACE=0
	else
echo "  ,"
	fi
echo	"  {\"interface\": \"${PHY_IF}\","
echo	"   \"type\": \"${RADIO_TYPE}\","
echo	"   \"data\": ["
	CHANNEL_NUM=`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF} | wc -l`
	INDEX=1
	FIRST_PRINTED_CHANNEL=1
	while [ ${INDEX} -le ${CHANNEL_NUM} ]
	do
		CHANNEL=`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF} | sed -n "${INDEX}p"  | awk -F')' '{print $1}' | awk -F '(' '{print $2}' | sed 's/ //g' `
		RESULT=`grep '"'^${CHANNEL}$'"' ${FILEPREFIX_TMPDATA}`
		if [ ! -z $RESULT ] ; then
			INDEX=`expr $INDEX + 1`
			continue
		else
			echo "${CHANNEL}" >> ${FILEPREFIX_TMPDATA}
		fi
		if [ "$FIRST_PRINTED_CHANNEL" = "1" ];then
			FIRST_PRINTED_CHANNEL=0
		else
			echo "  ,"
		fi
echo 		"    {\"channel\": \"${CHANNEL}\","
echo 		"    \"bssnumber\": \"`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF}  | sed -n "${INDEX}p"  | awk -F')' '{print $2}' | awk '{print $1}'`\","
	        MAXRSSI=`cat "${FILEPREFIX_ACSREPORT}_${PHY_IF}" | sed -n "${INDEX}p" | awk -F')' '{print $2}' | awk '{print $3}' | sed "s/ //g" `
	        NOISE=`cat "${FILEPREFIX_ACSREPORT}_${PHY_IF}" | sed -n "${INDEX}p" | awk -F')' '{print $2}' | awk '{print $4}' | sed "s/ //g"`
	        POWER=`expr ${MAXRSSI} + ${NOISE} `
echo 		"    \"minrssi\": \"`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF}  | sed -n "${INDEX}p"  | awk -F')' '{print $2}' | awk '{print $2}'`\","
echo 		"    \"maxrssi\": \"${MAXRSSI}\","
echo 		"    \"noise\": \"${NOISE}\","
echo		"    \"power\": \"${POWER}\","
echo 		"    \"load\": \"`cat ${FILEPREFIX_ACSREPORT}_${PHY_IF}  | sed -n "${INDEX}p"  | awk -F')' '{print $2}' | awk '{print $5}'`\"}"
		INDEX=`expr ${INDEX} + 1`
	done
echo	"   ]"
echo	"  }"
done
echo "],"
echo "\"ap\": ["
for PHY_IF in $PHYSICAL_IF_LIST; do
	if [ ! -f "${FILEPREFIX_IWLIST}_${PHY_IF}" ];then
	    iwlist ${PHY_IF} scan > ${FILEPREFIX_IWLIST}_${PHY_IF}
	fi
done
echo > ${FILEPREFIX_TMPDATA}
FIRST_INTERFACE=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	APNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | wc -l`
	if [ "${APNUM}" = "0" ] ; then
		continue
	fi
	MYCHANNEL=`iwlist ${PHY_IF} channel | sed 's/)//'|awk  '/Fre/ {print $5}'`
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
	if [ "$FIRST_INTERFACE" = "1" ];then
		FIRST_INTERFACE=0
	else
echo "  ,"
	fi
echo "  {\"channel\": \"${MYCHANNEL}\","
echo "   \"type\": \"${RADIO_TYPE}\","
echo "   \"data\":["
	INDEX=1
	NUMBER=0
	FIRSTDONE=0
	while [ ${INDEX} -le ${APNUM} ]
	do
		RESULTFILE="${FILEPREFIX_IWLIST}_${PHY_IF}_RESULT_"
		if [  ${INDEX} -eq ${APNUM} ] ; then
			STARTROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${INDEX}p`
			cat ${FILEPREFIX_IWLIST}_${PHY_IF} | sed -n "${STARTROWNUM},$ p" > ${RESULTFILE}
		else
			
			STARTROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${INDEX}p`
			ENDROWNUM=`expr ${INDEX} + 1`
			ENDROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${ENDROWNUM}p`
			ENDROWNUM=`expr ${ENDROWNUM} - 1`
			cat ${FILEPREFIX_IWLIST}_${PHY_IF} | sed -n ${STARTROWNUM},${ENDROWNUM}p > ${RESULTFILE}
		fi
		
		
		CHANNEL=`cat ${RESULTFILE} | grep 'Frequency:' | awk -F 'Channel ' '{print $2}' | sed 's/)//'`
		if [ "$CHANNEL" != "$MYCHANNEL" ];then
		    INDEX=`expr ${INDEX} + 1`
		    continue
		fi
		SSID=`cat ${RESULTFILE} | grep 'ESSID:' | awk -F ':' '{print $2}'`
		if [ "$SSID" = '""' ]; then
			INDEX=`expr $INDEX + 1`
			continue
		fi
		BSSID=`cat ${RESULTFILE} | grep ' Address: ' | awk -F ': ' '{print $2}'`
		if [ "$BSSID" = '""' ]; then
			INDEX=`expr $INDEX + 1`
			continue
		fi
		RESULT=`grep '"'^${BSSID}$'"' ${FILEPREFIX_TMPDATA}`
		if [ ! -z $RESULT ] ; then
			INDEX=`expr $INDEX + 1`
			continue
		else
			echo "${BSSID}" >> ${FILEPREFIX_TMPDATA}
		fi
		if [ "$FIRSTDONE" = "1" ]; then
		    echo "     ,"
		fi
		echo "	{\"ssid\": ${SSID},"
		echo "	 \"bssid\": \"`cat ${RESULTFILE} | grep ' Address: ' | awk -F ': ' '{print $2}'`\","
		echo "	 \"type\": \"${RADIO_TYPE}\","
		echo "	 \"channel\": \"`cat ${RESULTFILE} | grep 'Frequency:' | awk -F 'Channel ' '{print $2}' | sed 's/)//'`\","
		echo "	 \"rssi\": \"`cat ${RESULTFILE} | grep "Signal level=" | awk -F '=-' '{print $2}' | awk '{print $1}'`\","
		if [ -n "`cat ${RESULTFILE} | grep 'Encryption key:on'`" ] ; then
		echo "	 \"security\": \"`cat ${RESULTFILE} | grep "IE:" | sed -n 1p | awk -F '/' '{print $2}' | awk '{print $1}'`\","
		elif [ -n "`cat ${RESULTFILE} | grep 'Encryption key:off'`"  ] ; then
		echo "	 \"security\": \"off\","
		else
		echo "	 \"security\": \"\","
		fi
		echo "	 \"vendor\": \"\","
		MODE=`cat ${RESULTFILE}| grep "phy_mode=" | awk -F 'phy_mode=' '{print $2}'`
		echo "	 \"bandwidth\": \"`ModeToBandwidth ${MODE} | awk '{print $1}'`\","
		echo "	 \"mode\": \"${MODE}\"}"
		if [ "$FIRSTDONE" = "0" ]; then
			FIRSTDONE=1
		fi
		INDEX=`expr ${INDEX} + 1`
		NUMBER=`expr ${NUMBER} + 1`
		if [ "$WL_SYSCFG" = "wl0" ];then
			APNUM_SAMECHANNEL_WL0=`expr ${APNUM_SAMECHANNEL_WL0} + 1`
		elif [ "$WL_SYSCFG" = "wl1" ]; then
			APNUM_SAMECHANNEL_WL1=`expr ${APNUM_SAMECHANNEL_WL1} + 1`
		fi
	done
echo "  ],"
echo "  \"number\": \"${NUMBER}\"}"
done
echo "],"
echo "\"txpower\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
echo "	{\"name\": \"${PHY_IF}\","
echo "	\"type\":\"${RADIO_TYPE}\","
echo "	\"txpower\": \"`iwlist ${PHY_IF} txpower | grep "Current Tx-Power" | awk -F ':' '{print $2}' | awk '{print $1}'`\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr ${INDEX} + 1`
done
echo "]"
echo "};" 
}
ShowRadioInfo()
{
echo "var RadioInfo={"
echo "\"title\": \"radio information\","
echo "\"description\": \"basic radio information\","
PHYSICAL_NUM=`syscfg get lan_wl_physical_ifnames | awk '{print NF}'`
echo "\"number\": \"${PHYSICAL_NUM}\","
echo "\"data\": ["
INDEX=1
for PHY_IF in $PHYSICAL_IF_LIST; do
	GUEST_INTERFACE=""
	GUEST_SSID=""
	AP_NUM=1
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
		if [ "`syscfg get guest_enabled`" = "1" ] && [ "`syscfg get wl0_guest_enabled`" = "1" ] && [ `syscfg get guest_wifi_phy_ifname` = "$WL_SYSCFG" ]; then
			GUEST_INTERFACE="`syscfg get wl0_guest_vap`"
			GUEST_SSID=`syscfg get guest_ssid`
			AP_NUM=`expr $AP_NUM + 1`
		fi
	else
		RADIO_TYPE="5GHz"
		if [ "`syscfg get guest_enabled`" = "1" ] && [ "`syscfg get ${WL_SYSCFG}_guest_enabled`" = "1" ] && [ `syscfg get ${WL_SYSCFG}_guest_wifi_phy_ifname` = "$WL_SYSCFG" ]; then
			GUEST_INTERFACE="`syscfg get ${WL_SYSCFG}_guest_vap`"
			GUEST_SSID=`syscfg get ${WL_SYSCFG}_guest_ssid`
			AP_NUM=`expr $AP_NUM + 1`
		fi
	fi
	STA_EN="0"
	STA_MODE=""
	STA_BANDWIDTH=""
	STA_STATUS="disconnected"
	if [ "`syscfg get wifi_bridge::mode`" = "1" ] && [ "`syscfg get wifi_bridge::radio`" = "${RADIO_TYPE}" ];then
		if [ "${PHY_IF}" = "ath0" ];then
		    STA_EN="1"
		    STA_MODE="IEEE80211_MODE_11NG_HT40PLUS"
		    STA_BANDWIDTH="40MHz"
		elif [ "${PHY_IF}" = "ath1" ];then
		    STA_EN="1"
		    STA_MODE="IEEE80211_MODE_11AC_VHT80"
		    STA_BANDWIDTH="80MHz"
		fi
		if [ "`sysevent get wifi_sta_up`" = "1" ];then
		    STA_STATUS="connected"
		fi
	fi
echo "	{\"type\":\"${RADIO_TYPE}\","
echo "	 \"staEnabled\":\"${STA_EN}\","
	if [ "${STA_EN}" = "1" ];then
echo "	 \"sta\":[{"
echo "		\"mac\":\"`syscfg get wl0_sta_mac_addr | tr -d :`\","
echo "		\"status\":\"${STA_STATUS}\","
echo "		\"ssid\":\"`syscfg get wifi_bridge::ssid`\","
echo "		\"channel\":\"`syscfg get wifi_sta_channel`\","
echo "		\"security\":\"`syscfg get wifi_bridge::security_mode`\","
echo "		\"mode\":\"${STA_MODE}\","
echo "		\"bandwidth\":\"${STA_BANDWIDTH}\"}],"
	fi
echo "	 \"apNum\": \"${AP_NUM}\","
echo "	 \"ap\": ["
echo "	  	 {\"interface\": \"${PHY_IF}\","
echo "		  \"ssid\": \"`syscfg get ${WL_SYSCFG}_ssid`\","
echo "		  \"bssid\": \"`ifconfig ${PHY_IF} | grep HWaddr | awk '{print $5}'`\","
echo "		  \"security\": \"`syscfg get ${WL_SYSCFG}_security_mode`\","
echo "		  \"ClientNum\": \"`wlanconfig ${PHY_IF} list sta | sed "1d" | wc -l`\"}"
	if [ "${AP_NUM}" -gt "1" ];then
echo "		 ,"
echo "		 {\"interface\": \"${GUEST_INTERFACE}\","
echo "		  \"ssid\": \"${GUEST_SSID}\","
echo "		  \"bssid\": \"`ifconfig ${GUEST_INTERFACE} | grep HWaddr | awk '{print $5}'`\","
echo "		  \"security\": \"open\","
echo "		  \"ClientNum\": \"`wlanconfig ${GUEST_INTERFACE} list sta | sed "1d" | wc -l`\"}"
	fi
echo "	 ],"
echo "	 \"channel\": \"`iwlist ${PHY_IF} channel | sed 's/)//'|awk  '/Fre/ {print $5}'`\","
echo "	 \"band\": \"`syscfg get ${WL_SYSCFG}_radio_band`\","
echo "	 \"ComponentID\": \"88W8864\","
echo "	 \"beamformingEnable\": \"`syscfg get ${WL_SYSCFG}_txbf_enabled`\","
echo "	 \"mumimoEnable\": \"`syscfg get wifi::${WL_SYSCFG}_mumimo_enabled`\"}"
	if [ ${INDEX} -ne ${PHYSICAL_NUM} ] ; then
echo "  ,"
	fi
	INDEX=`expr $INDEX + 1`
done
echo "]};"
}
ModeToBandwidth()
{
	BANDWIDTH=""
	MODE="$1"
	case "$1" in
	    "IEEE80211_MODE_11A") 
		BANDWIDTH="20MHz";;
	    "IEEE80211_MODE_11B") 
		BANDWIDTH="20MHz";;
	    "IEEE80211_MODE_11G") 
		BANDWIDTH="20MHz";;
	    "IEEE80211_MODE_11NA_HT20") 
		BANDWIDTH="20MHz";;
	    "IEEE80211_MODE_11NG_HT20") 
		BANDWIDTH="20MHz";;
	    "IEEE80211_MODE_11NA_HT40PLUS") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11NA_HT40MINUS") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11NG_HT40PLUS") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11NG_HT40MINUS") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11NG_HT40") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11NA_HT40") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11AC_VHT20") 
		BANDWIDTH="20MHz";;
	    "IEEE80211_MODE_11AC_VHT40PLUS") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11AC_VHT40MINUS") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11AC_VHT40") 
		BANDWIDTH="40MHz";;
	    "IEEE80211_MODE_11AC_VHT80") 
		BANDWIDTH="80MHz";;
	    *)
		BANDWIDTH=""
		MODE=""
	esac
	echo "${BANDWIDTH} ${MODE}"
}
_STA_FIRSTDONE=0
TATOL_CLIENT_NUM=0
PrintClientOnInterface()
{
INTERFACE=$1
RADIO_TYPE=$2
APSSID=$3
PRINT_MODE=$4
STANUM=`wlanconfig ${INTERFACE} list sta | sed "1d" | wc -l`
if [ "${STANUM}" = "0" ] ; then
	return
fi
INDEX=1
while [ ${INDEX} -le ${STANUM} ]
do
	CNT=`expr $INDEX + 1`
	INDEX=`expr $INDEX + 1`
	MODE=`wlanconfig ${INTERFACE} list sta | sed -n ${CNT}p | sed 's/IEEE80211/\n&/' | awk NR==2'{print $1}'`
	BANDWIDTH=`ModeToBandwidth ${MODE} | awk '{print $1}'`
	if [ "${PRINT_MODE}" = "legacy" ]; then
		if [ "${MODE}" != "IEEE80211_MODE_11A" ] && [ "${MODE}" != "IEEE80211_MODE_11B" ] && [ "${MODE}" != "IEEE80211_MODE_11G" ]; then
			continue #not a legacy client
		fi
	fi
	CLIENT_RSSI="`wlanconfig ${INTERFACE} list sta | awk NR==${CNT}{'print $6'}`"
	if [ "${PRINT_MODE}" = "poor" ] && [ "$GLOBAL_POORCLIENT_SIGNAL_THRESHOLD" != "0" ]; then
		if [[ "$CLIENT_RSSI" -lt "$GLOBAL_POORCLIENT_SIGNAL_THRESHOLD"  ]]; then
			continue #this client's signal is not poor
		fi
	fi
	if [ "$_STA_FIRSTDONE" != "0" ]; then
		echo "  ,"
	fi
echo "	{\"mac\": \"`wlanconfig ${INTERFACE} list sta | awk NR==${CNT}{'print $1'}`\","
echo "	 \"type\": \"${RADIO_TYPE}\","
echo "	 \"interface\": \"${INTERFACE}\","
echo "	 \"APSSID\": \"${APSSID}\","
echo "	 \"rssi\": \"${CLIENT_RSSI}\","
echo "	 \"mode\": \"${MODE}\","
echo "	 \"rate\": \"`wlanconfig ${INTERFACE} list sta | awk NR==${CNT}{'print $5'}`\","
echo "	 \"bandwidth\": \"${BANDWIDTH}\","
echo "	 \"mumimo\": \"\","
echo "	 \"channel\": \"`wlanconfig ${INTERFACE} list sta | awk NR==${CNT}{'print $3'}`\"}"
	TATOL_CLIENT_NUM=`expr $TATOL_CLIENT_NUM + 1`
	_STA_FIRSTDONE=1
done
}
ShowClientInfo()
{
TATOL_CLIENT_NUM=0
_STA_FIRSTDONE=0
PRINT_MODE=$1
if [ "${PRINT_MODE}" = "legacy" ];then
	echo "var CurrentLegacyClientInfo={"
	echo "\"title\": \"legacy wifi clients\","
	echo "\"description\": \"legacy wifi clients, for 802.11abg\","
elif [ "${PRINT_MODE}" = "poor" ] ; then 
	echo "var PoorClientInfo={"
	echo "\"title\": \"poor wifi clients\","
	echo "\"description\": \"wifi clients with the signal worse than ${GLOBAL_POORCLIENT_SIGNAL_THRESHOLD}\","
else
	echo "var ClientInfo={"
	echo "\"title\": \"wifi clients\","
	echo "\"description\": \"all wifi clients\","
fi
echo "\"time\": \"`date +"%F %H:%M:%S"`\","
echo "\"data\": ["
for PHY_IF in $PHYSICAL_IF_LIST; do
	GUEST_INTERFACE=""
	GUEST_SSID=""
	AP_NUM=1
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
		if [ "`syscfg get guest_enabled`" = "1" ] && [ "`syscfg get wl0_guest_enabled`" = "1" ] && [ `syscfg get guest_wifi_phy_ifname` = "$WL_SYSCFG" ]; then
			GUEST_INTERFACE="`syscfg get wl0_guest_vap`"
			GUEST_SSID=`syscfg get guest_ssid`
			AP_NUM=`expr $AP_NUM + 1`
		fi
	else
		RADIO_TYPE="5GHz"
		if [ "`syscfg get guest_enabled`" = "1" ] && [ "`syscfg get ${WL_SYSCFG}_guest_enabled`" = "1" ] && [ `syscfg get ${WL_SYSCFG}_guest_wifi_phy_ifname` = "$WL_SYSCFG" ]; then
			GUEST_INTERFACE="`syscfg get ${WL_SYSCFG}_guest_vap`"
			GUEST_SSID=`syscfg get ${WL_SYSCFG}_guest_ssid`
			AP_NUM=`expr $AP_NUM + 1`
		fi
	fi
	SSID=`syscfg get ${WL_SYSCFG}_ssid`
	PrintClientOnInterface ${PHY_IF} ${RADIO_TYPE} ${SSID} ${PRINT_MODE}
	if [ "$AP_NUM" -gt "1" ];then
	    PrintClientOnInterface ${GUEST_INTERFACE} ${RADIO_TYPE} ${GUEST_SSID} ${PRINT_MODE}
	fi
done
echo "],"
echo "\"number\": \"${TATOL_CLIENT_NUM}\"};"
}
ShowAllClientInfo()
{
ShowClientInfo "normal"
}
ShowLegacyClientInfo()
{
if [ -f "${HISTORY_DATA}" ]; then
	cat "${HISTORY_DATA}" | sed '1a''var LastLegacyClientInfo={' | sed '1d'
else
	touch "${HISTORY_DATA}"
fi 
echo > "${HISTORY_DATA}"
ShowClientInfo "legacy" | tee "${HISTORY_DATA}"
}
ShowPoorClientInfo()
{
ShowClientInfo "poor"
}
ShowAP_Nonblocked()
{
TOTAL_CNT=0
APNUMBER=0
for PHY_IF in $PHYSICAL_IF_LIST; do
	NUM=`wlanconfig ${PHY_IF} list ap | sed "1d" | wc -l`
	APNUMBER=`expr $APNUMBER + $NUM`
done
if [ "$GLOBAL_AP_MAX" != "0" ] && [ "$APNUMBER" -gt "$GLOBAL_AP_MAX" ] ; then
	APNUMBER="$GLOBAL_AP_MAX"
fi
echo "var APInfo={"
echo "\"title\": \"site survey\","
echo "\"description\": \"the detail about the adjacent AP\","
echo "\"data\": ["
FIRSTDONE=0
DONE2G=0
DONE5G=0
for PHY_IF in $PHYSICAL_IF_LIST; do
	APNUM=`wlanconfig ${PHY_IF} list ap | sed '1d' | wc -l `
	if [ "${APNUM}" = "0" ] ; then
		continue
	fi
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
	if [ "$RADIO_TYPE" = "2.4GHz" ] && [ "$DONE2G" = "1" ];then
		continue
	elif [ "$RADIO_TYPE" = "2.4GHz" ] && [ "$DONE2G" = "0" ];then
		DONE2G=1
	elif [ "$RADIO_TYPE" = "5GHz" ] && [ "$DONE5G" = "1" ];then
		continue
	elif [ "$RADIO_TYPE" = "5GHz" ] && [ "$DONE5G" = "0" ];then
		DONE5G=1
	fi
		
	if [ "$FIRSTDONE" = "1" ]; then
echo "  ,"
	fi	
	if [ "$FIRSTDONE" = "0" ]; then
		FIRSTDONE=1
	fi
	INDEX=1
	while [ ${INDEX} -le ${APNUM} ]
	do
		CNT=`expr $INDEX + 1`
echo "	{\"ssid\": \"`wlanconfig ${PHY_IF} list ap | awk NR==${CNT}{'print $1'}`\","
echo "	 \"bssid\": \"\","
echo "	 \"type\": \"${RADIO_TYPE}\","
echo "	 \"channel\": \"`wlanconfig ${PHY_IF} list ap | awk NR==${CNT}{'print $3'}`\","
echo "	 \"rssi\": \"`wlanconfig ${PHY_IF} list ap | awk NR==${CNT}{'print $5'} | awk -F ':' '{print $1}'`\","
echo "	 \"security\": \"\","
echo "	 \"vendor\": \"\","
echo "	 \"bandwidth\": \"\","
echo "	 \"mode\": \"\"}"
		TOTAL_CNT=`expr $TOTAL_CNT + 1`
		if [ "$GLOBAL_AP_MAX" != "0" ] && [ "$TOTAL_CNT" -ge "$GLOBAL_AP_MAX" ]; then
			break
		fi
		if [ ${INDEX} -ne ${APNUM} ] ; then
echo "  ,"
		fi
		INDEX=`expr $INDEX + 1`
	done
	if [ "$GLOBAL_AP_MAX" != "0" ] && [ "$TOTAL_CNT" -ge "$GLOBAL_AP_MAX" ]; then
		break
	fi
done
echo "],"
echo "\"number\": \"${APNUMBER}\""
echo "};"
}
ShowAP_Blocked() 
{
for PHY_IF in $PHYSICAL_IF_LIST; do
	if [ ! -f "${FILEPREFIX_IWLIST}_${PHY_IF}" ];then
	    iwlist ${PHY_IF} scan > ${FILEPREFIX_IWLIST}_${PHY_IF}
	fi
done
echo > ${FILEPREFIX_TMPDATA}
echo "var APInfo={"
echo "\"title\": \"site survey\","
echo "\"description\": \"the detail about the adjacent AP\","
echo "\"data\": ["
TOTAL_CNT=0
FIRSTDONE=0
DONE2G=0
DONE5G=0
for PHY_IF in $PHYSICAL_IF_LIST; do
	APNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | wc -l`
	if [ "${APNUM}" = "0" ] ; then
		continue
	fi
	WL_SYSCFG=`syscfg get ${PHY_IF}_syscfg_index`
	if [ "$WL_SYSCFG" = "wl0" ] ; then
		RADIO_TYPE="2.4GHz"
	else
		RADIO_TYPE="5GHz"
	fi
	if [ "$RADIO_TYPE" = "2.4GHz" ] && [ "$DONE2G" = "1" ];then
		continue
	elif [ "$RADIO_TYPE" = "2.4GHz" ] && [ "$DONE2G" = "0" ];then
		DONE2G=1
	elif [ "$RADIO_TYPE" = "5GHz" ] && [ "$DONE5G" = "1" ];then
		continue
	elif [ "$RADIO_TYPE" = "5GHz" ] && [ "$DONE5G" = "0" ];then
		DONE5G=1
	fi
	INDEX=1
	while [ ${INDEX} -le ${APNUM} ]
	do
		RESULTFILE="${FILEPREFIX_IWLIST}_${PHY_IF}_RESULT_"
		if [  ${INDEX} -eq ${APNUM} ] ; then
			STARTROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${INDEX}p`
			cat ${FILEPREFIX_IWLIST}_${PHY_IF} | sed -n "${STARTROWNUM},$ p" > ${RESULTFILE}
		else
			
			STARTROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${INDEX}p`
			ENDROWNUM=`expr $INDEX + 1`
			ENDROWNUM=`cat ${FILEPREFIX_IWLIST}_${PHY_IF} | grep ' Address: ' -n | awk -F ':' '{print $1}' | sed -n ${ENDROWNUM}p`
			ENDROWNUM=`expr $ENDROWNUM - 1`
			cat ${FILEPREFIX_IWLIST}_${PHY_IF} | sed -n ${STARTROWNUM},${ENDROWNUM}p > ${RESULTFILE}
		fi
		SSID=`cat ${RESULTFILE} | grep 'ESSID:' | awk -F ':' '{print $2}'`
		if [ "$SSID" = '""' ]; then
			INDEX=`expr $INDEX + 1`
			continue
		fi
		BSSID=`cat ${RESULTFILE} | grep ' Address: ' | awk -F ': ' '{print $2}'`
		if [ "$BSSID" = '""' ]; then
			INDEX=`expr $INDEX + 1`
			continue
		fi
		RESULT=`grep '"'^${BSSID}$'"' ${FILEPREFIX_TMPDATA}`
		if [ ! -z $RESULT ] ; then
			INDEX=`expr $INDEX + 1`
			continue
		else
			echo "${BSSID}" >> ${FILEPREFIX_TMPDATA}
		fi
		if [ "$FIRSTDONE" = "1" ]; then
			echo 	"    ,"
		fi	
		if [ "$FIRSTDONE" = "0" ]; then
			FIRSTDONE=1
		fi
		echo "	{\"ssid\": ${SSID},"
		echo "	 \"bssid\": \"`cat ${RESULTFILE} | grep ' Address: ' | awk -F ': ' '{print $2}'`\","
		echo "	 \"type\": \"${RADIO_TYPE}\","
		echo "	 \"channel\": \"`cat ${RESULTFILE} | grep 'Frequency:' | awk -F 'Channel ' '{print $2}' | sed 's/)//'`\","
		echo "	 \"rssi\": \"`cat ${RESULTFILE} | grep "Signal level=" | awk -F '=-' '{print $2}' | awk '{print $1}'`\","
		if [ -n "`cat ${RESULTFILE} | grep 'Encryption key:on'`" ] ; then
		echo "	 \"security\": \"`cat ${RESULTFILE} | grep "IE:" | sed -n 1p | awk -F '/' '{print $2}' | awk '{print $1}'`\","
		elif [ -n "`cat ${RESULTFILE} | grep 'Encryption key:off'`"  ] ; then
		echo "	 \"security\": \"off\","
		else
		echo "	 \"security\": \"\","
		fi
		echo "	 \"vendor\": \"\","
		MODE=`cat ${RESULTFILE}| grep "phy_mode=" | awk -F 'phy_mode=' '{print $2}'`
		echo "	 \"bandwidth\": \"`ModeToBandwidth ${MODE} | awk '{print $1}'`\","
		echo "	 \"mode\": \"${MODE}\"}"
		TOTAL_CNT=`expr $TOTAL_CNT + 1`
		if [ "$GLOBAL_AP_MAX" != "0" ] && [ "$TOTAL_CNT" -ge "$GLOBAL_AP_MAX" ]; then
			break
		fi
		INDEX=`expr $INDEX + 1`
	done
	if [ "$GLOBAL_AP_MAX" != "0" ] && [ "$TOTAL_CNT" -ge "$GLOBAL_AP_MAX" ]; then
		break
	fi
done
echo "],"
echo "\"number\": \"${TOTAL_CNT}\""
echo "};"
}
PROCEED_NAME=`basename $0`
SignalHandler()
{
PrintLog "get termial signal,clear and exit"
sysevent set getwifiinfo-status stopped
rm ${HISTORY_DATA} -rf
}
trap 'SignalHandler;exit' 1 2 3 15
echo > /tmp/.errorLogForGetWifiInfo
exec 2>/tmp/.errorLogForGetWifiInfo
VENDOR=`syscfg get hardware_vendor_name | sed s/[[:space:]]//g`
if [ "$VENDOR" != "QCA" ]; then
	PrintLog "error--this script is for QCA, but syscfg get ${VENDOR}"
	exit
fi
GLOBAL_SECTION_EN_CA="0"
GLOBAL_SECTION_EN_BASIC="0"
GLOBAL_SECTION_EN_RADIO="0"
GLOBAL_SECTION_EN_CLIENT="0"
GLOBAL_SECTION_EN_AP="0"
GLOBAL_SECTION_EN_LEGACYCLIENT="0"
GLOBAL_SECTION_EN_POORCLIENT="0"
GLOBAL_AP_MODE="blocked"
GLOBAL_AP_MAX="300"
GLOBAL_POORCLIENT_SIGNAL_THRESHOLD="0" 
if [ $# -ge 1 ]; then
	for arg in "$@"
	do
	    case $arg in 
		"ca") 
			GLOBAL_SECTION_EN_CA="1";;
		"basic") 
			GLOBAL_SECTION_EN_BASIC="1";;
		"radio") 
			GLOBAL_SECTION_EN_RADIO="1";;
		"client") 
			GLOBAL_SECTION_EN_CLIENT="1";;
		"poorclient")
			GLOBAL_SECTION_EN_POORCLIENT="1";;
		"legacyclient") 
			GLOBAL_SECTION_EN_LEGACYCLIENT="1";;
		"ap")
			GLOBAL_SECTION_EN_AP="1";;
		"clear")
			killall $PROCEED_NAME >/dev/null 2>&1
			sysevent set getwifiinfo-status stopped
			rm ${HISTORY_DATA} -rf
			exit;;
		*)
			NUM=`echo "$arg" | awk -F 'apmax=' '{print $2}'`
			if [ -n "${NUM}" ]; then
				GLOBAL_AP_MAX="$NUM"
			fi
			MODE=`echo "$arg" | awk -F 'mode=' '{print $2}'`
			if [ -n "${MODE}" ]; then
				if [ "$MODE" = "nonblocked" ]; then
				    GLOBAL_AP_MODE="nonblocked"
				else
				    GLOBAL_AP_MODE="blocked"
				fi
			fi
			SIGNAL_THRESHOLD=`echo "$arg" | awk -F 'signalthreshold=' '{print $2}'`
			if [ -n "${SIGNAL_THRESHOLD}" ]; then
				GLOBAL_POORCLIENT_SIGNAL_THRESHOLD="$SIGNAL_THRESHOLD"
			fi
			;;
	    esac
	done
fi
GETWIFIINFO_STATUS=`sysevent get getwifiinfo-status`
if [ "${GETWIFIINFO_STATUS}" != "started" ];then
	sysevent set getwifiinfo-status started
else
	PrintLog "other proceeds is working"
	exit
fi
rm ${TMP_FILEPREFIX}* -f
if [ "${GLOBAL_SECTION_EN_BASIC}" = "1" ]; then
	ShowBasicInfo
fi
if [ "${GLOBAL_SECTION_EN_RADIO}" = "1" ]; then
	ShowRadioInfo
fi
if [ "${GLOBAL_SECTION_EN_CLIENT}" = "1" ]; then
	ShowAllClientInfo
fi
if [ "${GLOBAL_SECTION_EN_LEGACYCLIENT}" = "1" ]; then
	ShowLegacyClientInfo
fi
if [ "${GLOBAL_SECTION_EN_POORCLIENT}" = "1" ]; then
	ShowPoorClientInfo
fi
if [ "${GLOBAL_SECTION_EN_CA}" = "1" ]; then
	showCAInfoForAllChannel
fi
if [ "${GLOBAL_SECTION_EN_AP}" = "1" ]; then
	if [ "${GLOBAL_AP_MODE}" = "blocked" ]; then
	    ShowAP_Blocked
	else
	    ShowAP_Nonblocked
	fi
fi
rm ${TMP_FILEPREFIX}* -f
sysevent set getwifiinfo-status stopped
exit

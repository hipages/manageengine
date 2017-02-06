#!/usr/bin/env bash

usage() {
cat << EOF
  usage: $0 options

  OPTIONS:
    -h ServiceDesk Hostname (e.g. servicedesk.corp.hipagesgroup.com.au)
    -p ServiceDesk Port (default: 80)
    -s ServiceDesk Schema (default: http)
    -i Run interval (default: 3600s)
    -u Disable auto-update
    -r Uninstall
EOF
exit 1;
}

while getopts "h:p:s:i:ru" OPTION; do
  case ${OPTION} in
    h) HOST=${OPTARG};;
    p) PORT=${OPTARG};;
    s) SCHEMA=${OPTARG};;
    i) INTERVAL=${OPTARG};;
    u) NO_AUTO_UPDATE=1;;
    r) UNINSTALL=1;;
  esac
done

if [[ $UID != 0 ]]; then
    echo "Please start the script as root or sudo!"
    exit 1
fi

if [ -z "${HOST}" ]; then
  echo "$0 params missing, need to stipulate a hostname"
  usage
fi

PORT=${PORT:-80}
SCHEMA=${SCHEMA:-http}
INTERVAL=${INTERVAL:-3600}

LAUNCHD_PATH=/Library/LaunchDaemons
LAUNCHD_NAME=com.manageengine.servicedesk.scan.interval.mac

AESCAN_PATH=/opt/local/bin
AESCAN_NAME=ae-scan-mac

AESCAN_CONTENT=$(cat <<AESCAN_CONTENT
#!/bin/sh

############ Server details ############

hostName="${HOST}"
portNo="${PORT}"
protocol="${SCHEMA}"

############ Server details ############

SUPPORT="assetexplorer-support@manageengine.com"
PRODUCT="AssetExplorer"

COMPUTERNAME=$(hostname)
OUTPUTFILE="$COMPUTERNAME.xml"


main()
{
	logger -t ${LAUNCHD_NAME} "##### Scanning Started #####"
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><DocRoot>" > \$OUTPUTFILE
	constructXML "ComputerName" "hostname"
	constructXML "OS_Category" "uname -s"
	echo "<Hardware_Info>" >> \$OUTPUTFILE
	constructXML "OS_Category" "sw_vers"
	constructXML "Memory_Information" "sysctl hw.physmem"
	constructXML "Memory_Information" "sysctl hw.usermem"
	constructXML "Memory_Informationw" "sysctl hw.memsize"
	constructXML "Memory_Information" "sysctl vm.swapusage"
	constructXML "Computer_Information" "hostname"
	constructXML "Computer_Information" "hostname -s"
	constructXML "CPU_Information" "system_profiler SPHardwareDataType"
	constructXML "Disk_Space" "df -k"
	constructXML "NIC_Info" "/sbin/ifconfig"
	#-----------Last logged in user name -----------
	constructXML "Last_logged_user" "finger"
	#-------------Chipset, VRAM, Monitor display type, resolution---------------------
	constructXML "Monitoranddisplayinfo" "/usr/sbin/system_profiler SPDisplaysDataType"
	#--------------Sound card -----------------------------
	constructXML "SoundCardinfo" "/usr/sbin/system_profiler SPAudioDataType"
	#---------------Memory modules----------------------
	constructXML "MemoryInfo" "/usr/sbin/system_profiler SPMemoryDataType"
	#--------------Physical drives-------------------------
	constructXML "PhysicaldrivesInfo" "/usr/sbin/system_profiler SPParallelATADataType"
	#--------------Harddisk info if no data is available in SPParallelATADataType------------
	constructXML "HarddrivesInfo" "/usr/sbin/system_profiler SPSerialATADataType"
	#----------------Printer Info-----------------------
	constructXML "Printer_Info" "/usr/sbin/system_profiler SPPrintersDataType -xml"
	echo "</Hardware_Info>" >> \$OUTPUTFILE
	echo "<Software_Info>" >> \$OUTPUTFILE
	constructXML "Installed_Softwares" "system_profiler SPApplicationsDataType"
	echo "</Software_Info>" >> \$OUTPUTFILE
	echo "</DocRoot>" >> \$OUTPUTFILE
	logger -t ${LAUNCHD_NAME} "##### Scanning completed #####"
	pushData
}

constructXML()
{
	##Need to replace the < into &lt; , > into &gt; and & into &amp;#####
	echo "<\$1><command>\$2</command><output><![CDATA[">> \$OUTPUTFILE
	eval \$2 >> \$OUTPUTFILE 2>&1
	echo "]]></output></\$1>" >> \$OUTPUTFILE
}

pushData()
{
        eval "type curl > /dev/null 2>&1"

        if [ \$? -ne 0 ]
        then
                logger -t ${LAUNCHD_NAME} "curl is not installed, so could not post the scan data to \$PRODUCT, You can import the \$COMPUTERNAME.xml available in the current directory into \$PRODUCT using Stand Alone Workstations Audit. Executing the curl command will lead to the installation."
                exit 1
        fi

	      curl -s -o /dev/null --header "Content-Type: text/xml" --data-binary @\$OUTPUTFILE "\$protocol://\$hostName:\$portNo/discoveryServlet/WsDiscoveryServlet?COMPUTERNAME=\$COMPUTERNAME"
        if [ \$? -ne 0 ]
        then
           logger -t ${LAUNCHD_NAME} "\$PRODUCT is not reachable. You can import the  \$COMPUTERNAME.xml available in the current directory into \$PRODUCT using Stand Alone Workstations Audit. For further queries, please contact \$SUPPORT."
        else
           rm -rf \$OUTPUTFILE
           logger -t ${LAUNCHD_NAME} "Successfully scanned the system data, Find this machine details in \$PRODUCT server."
        fi
}

main \$*
AESCAN_CONTENT
)

LAUNCHD_CONTENT=$(cat <<LAUNCHD_CONTENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-/Apple/DTD PLIST 1.0/EN" "http:/www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>${LAUNCHD_NAME}</string>
    <key>ProgramArguments</key>
    <array>
      <string>${AESCAN_PATH}/${AESCAN_NAME}</string>
    </array>
    <key>StandardErrorPath</key>
    <string>/var/log/${LAUNCHD_NAME}_err.log</string>
    <key>StandardOutPath</key>
    <string>/var/log/${LAUNCHD_NAME}.log</string>
    <key>StartInterval</key>
    <integer>${INTERVAL}</integer>
  </dict>
</plist>
LAUNCHD_CONTENT
)

LAUNCHD_AUTO_UPDATE_PATH=/Library/LaunchDaemons
LAUNCHD_AUTO_UPDATE_NAME=com.manageengine.servicedesk.scan.update.mac
LAUNCHD_AUTO_UPDATE_CONTENT=$(cat <<LAUNCHD_AUTO_UPDATE_CONTENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-/Apple/DTD PLIST 1.0/EN" "http:/www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>${LAUNCHD_AUTO_UPDATE_NAME}</string>
    <key>ProgramArguments</key>
    <array>
      <string>bash &lt;(curl -s https://raw.githubusercontent.com/hipages/manageengine/master/asset-explorer/ae_scan_mac_scheduled.sh) $@</string>
    </array>
    <key>StandardErrorPath</key>
    <string>/var/log/${LAUNCHD_AUTO_UPDATE_NAME}_err.log</string>
    <key>StandardOutPath</key>
    <string>/var/log/${LAUNCHD_AUTO_UPDATE_NAME}.log</string>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>
      <integer>10</integer>
      <key>Minute</key>
      <integer>15</integer>
      <key>Weekday</key>
      <integer>2</integer>
    </dict>
  </dict>
</plist>
LAUNCHD_AUTO_UPDATE_CONTENT
)

if [ -n "${UNINSTALL+1}" ]; then
  echo "Uninstalling LaunchDaemons"

  if [ -f "${LAUNCHD_PATH}/${LAUNCHD_NAME}.plist" ]; then
    echo " > Removing ${LAUNCHD_NAME}"
    launchctl unload -w "${LAUNCHD_PATH}/${LAUNCHD_NAME}.plist"
    rm -f "${LAUNCHD_PATH}/${LAUNCHD_NAME}.plist"
  fi

  if [ -f "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist" ]; then
    echo " > Removing ${LAUNCHD_AUTO_UPDATE_NAME}"
    launchctl unload -w "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist"
    rm -f "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist"
  fi

  echo " > Removing ${AESCAN_NAME}"
  rm -f "${AESCAN_PATH}/${AESCAN_NAME}"

  exit 0
fi

[ -f "${LAUNCHD_PATH}/${LAUNCHD_NAME}.plist" ] && launchctl unload -w "${LAUNCHD_PATH}/${LAUNCHD_NAME}.plist"
mkdir -p "${AESCAN_PATH}"
printf %s\\n "${AESCAN_CONTENT}" > "${AESCAN_PATH}/${AESCAN_NAME}"
chmod 755 "${AESCAN_PATH}/${AESCAN_NAME}"

printf %s\\n "${LAUNCHD_CONTENT}" > "${LAUNCHD_PATH}/${LAUNCHD_NAME}.plist"
launchctl load -w "${LAUNCHD_PATH}/${LAUNCHD_NAME}.plist"

if [ -n "${NO_AUTO_UPDATE+1}" ]; then
  [ -f "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist" ] && launchctl unload -w "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist"
  rm -f "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist"
else
  printf %s\\n "${LAUNCHD_AUTO_UPDATE_CONTENT}" > "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist"
  launchctl load -w "${LAUNCHD_AUTO_UPDATE_PATH}/${LAUNCHD_AUTO_UPDATE_NAME}.plist"
fi

exit 0

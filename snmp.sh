#!/bin/bash


echo Input server address and port
read serverAddress

echo Input SNMP options
read snmpOptions

echo $snmpOptions $serverAddress

while true; do

	serverName=$(snmpwalk $snmpOptions -Oqvt $serverAddress SNMPv2-MIB::sysName.0)
	echo $serverName

	systemUpTime=$(snmpwalk $snmpOptions -OqvT $serverAddress HOST-RESOURCES-MIB::hrSystemUptime.0)
	systemUpTime=$(snmpwalk $snmpOptions -OqvT $serverAddress HOST-RESOURCES-MIB::hrSystemUptime.0)
	echo 'Uptime;' $systemUpTime

	processorIdle=$(snmpwalk $snmpOptions -Oqv $serverAddress UCD-SNMP-MIB::ssCpuIdle.0)
	processorLoad=$(snmpwalk $snmpOptions -Oqv $serverAddress HOST-RESOURCES-MIB::hrProcessorLoad)
	echo 'Total CPU Load;' $(expr 100 - $processorIdle)%
	echo 'CPU Core Load;' $processorLoad

	memoryTotalReal=$(snmpwalk $snmpOptions -Oqv $serverAddress UCD-SNMP-MIB::memTotalReal)
	memoryAvailReal=$(snmpwalk $snmpOptions -Oqv $serverAddress UCD-SNMP-MIB::memAvailReal)
	memoryTotalReal=${memoryTotalReal/" kB"/}
	memoryAvailReal=${memoryAvailReal/" kB"/}
	echo 'Total RAM;' $(expr $memoryTotalReal / 1024) 'MB'
	echo 'Available RAM;' $(expr $memoryAvailReal / 1024) 'MB'
	echo 'Used RAM;' $(expr $(expr $memoryTotalReal - $memoryAvailReal) / 1024) 'MB'

	tcpCurrentEstablished=$(snmpwalk $snmpOptions -Oqvs $serverAddress TCP-MIB::tcpCurrEstab.0)
	echo 'Total Connection;' $tcpCurrentEstablished

	connectedOIDList=()

	while read -r line; do
		if [[ ${line: -1} == 5 ]]; then
			connStateOID=${line/'tcpConnState.'/}
			connStateOID=${connStateOID/' 5'/}
			connectedOIDList+=($connStateOID)
		fi
	done < <(snmpwalk $snmpOptions -Oqse $serverAddress 1.3.6.1.2.1.6.13.1.1)

	for OIDs in ${connectedOIDList[@]}; do
		tcpConnRemAddress=$(snmpwalk $snmpOptions -Oqv $serverAddress TCP-MIB::tcpConnRemAddress.$OIDs)		
		if [[ $tcpConnRemAddress != 127* ]]; then
			tcpConnLocalPort=$(snmpwalk $snmpOptions -Oqv $serverAddress TCP-MIB::tcpConnLocalPort.$OIDs)		
			tcpConnRemPort=$(snmpwalk $snmpOptions -Oqv $serverAddress TCP-MIB::tcpConnRemPort.$OIDs)
			echo :$tcpConnLocalPort '----' $tcpConnRemAddress:$tcpConnRemPort
		fi
	done


	allocUnits=$(snmpwalk $snmpOptions -OqvU $serverAddress HOST-RESOURCES-MIB::hrStorageAllocationUnits.36)
	hrStorageSize=$(snmpwalk $snmpOptions -Oqv $serverAddress HOST-RESOURCES-MIB::hrStorageSize.36)
	hrStorageUsed=$(snmpwalk $snmpOptions -Oqv $serverAddress HOST-RESOURCES-MIB::hrStorageUsed.36)
	echo 'Storage Total;' $(expr $hrStorageSize \* $allocUnits / 1024 / 1024 / 1024) 'GB'
	echo 'Storage Used;' $(expr $hrStorageUsed \* $allocUnits / 1024 / 1024 / 1024) 'GB'
	echo ''
	sleep 3
done



# -O OUTOPTS	Toggle various defaults controlling output display:
# 	0:  print leading 0 for single-digit hex characters
# 	a:  print all strings in ascii format
# 	b:  do not break OID indexes down
# 	e:  print enums numerically
# 	E:  escape quotes in string indices
# 	f:  print full OIDs on output
# 	n:  print OIDs numerically
# 	q:  quick print for easier parsing
# 	Q:  quick print with equal-signs
# 	s:  print only last symbolic element of OID
# 	S:  print MIB module-id plus last element
# 	t:  print timeticks unparsed as numeric integers
# 	T:  print human-readable text along with hex strings
# 	u:  print OIDs using UCD-style prefix suppression
# 	U:  don't print units
# 	v:  print values only (not OID = value)
# 	x:  print all strings in hex format
# 	X:  extended index format
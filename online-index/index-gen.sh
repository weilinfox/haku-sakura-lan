#!/bin/bash
##########################################################
#                 sakura-lan online-index                #
#                                                        #
# ping ip list in ips.json,                              #
# generate result html table                             #
# and put head.html, table and tail.html together.       #
# index.html is the result html document.                #
#                                                        #
##########################################################
# Author: weilinfox                                      #
# Date  : 2022/09/18                                     #
##########################################################

export LC_ALL=C
export LANG=C.UTF-8

set -e

script_path=$(cd $(dirname $0); pwd)
cache_file=${script_path}/cache.html
output_file=${script_path}/index.html

cfg_json=$( cat ${script_path}/ips.json )
ips=$( echo ${cfg_json} | jq -cM ".ips" )
nmap_ips=$( echo ${cfg_json} | jq -cM ".nmap" | cut -d\" -f2 )
ipl=$( echo $ips | jq -cM "length" )

nmap -version 1>&/dev/null

echo "Scan $ipl IP(s)"
echo "Scan ${nmap_ips}"

set +e

delay=0

while true; do

	cat ${script_path}/head.html > ${cache_file}
	echo "<dt>&nbsp;&nbsp;Ping status, IP and descriptions (F5 to refresh)</dt>" >> ${cache_file}

	pos=0
	while true; do
		item=$( echo $ips | jq -cM ".[$pos]" )
		if [ "$item" == "null" ]; then
			break
		fi

		ip=$( echo $item | jq -cM ".ip" | cut -d\" -f2 )
		de=$( echo $item | jq -cM ".de" | cut -d\" -f2 )
		# echo $item $ip $de
		p=( $(ping -c 5 -w 5 -q $ip 2>&1) )
		length=${#p[@]}
		# echo $lengh

		if [ "${p[ $(expr ${length} - 1) ]}" == "ms" ]; then
			line="$( echo ${p[ $(expr ${length} - 2) ]} | cut -d/ -f2 ) ms"
			echo "<dd><span class=\"online\">$line</span>&emsp;&emsp;&emsp;&emsp;$ip&emsp;&emsp;&emsp;&emsp;$de</dd>" >> ${cache_file}
		else
			echo "<dd><span class=\"offline\">Offline</span>&emsp;&emsp;&emsp;&emsp;$ip</dd>" >> ${cache_file}
		fi
		pos=$( expr $pos + 1 )
	done

	# nmap scan
	if [ $delay -eq 0 ]; then
		delay=10

		echo "<dd>&nbsp;</dd>" >> ${cache_file}
		echo "<dt>&nbsp;&nbsp;Proxy nmap scan result</dt>" >> ${cache_file}

		nm=$( nmap -sn -T4 ${nmap_ips} )
		old_ifs=$IFS
		IFS=$'\n'

		for m in $nm; do
			echo "<dd>$m</dd>" >> ${cache_file}
		done

		IFS=${old_ifs}
	fi
	delay=$( expr $delay - 1 )

	cat ${script_path}/tail.html >> ${cache_file}
	mv ${cache_file} ${output_file}

	sleep 5m

	set -e
	cfg_json=$( cat ${script_path}/ips.json )
	ips=$( echo ${cfg_json} | jq -cM ".ips" )
	nmap_ips=$( echo ${cfg_json} | jq -cM ".nmap" )
	ipl=$( echo $ips | jq -cM "length" )
	set +e

done


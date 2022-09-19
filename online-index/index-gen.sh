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
ips=$( cat ${script_path}/ips.json )
ipl=$( echo $ips | jq -cM "length" )

echo "Scan $ipl IP(s)"

set +e

while true; do

	cat ${script_path}/head.html > ${cache_file}
	echo "<dt>&nbsp;&nbsp;IP, ping status and descriptions (F5 to refresh)</dt>" >> ${cache_file}

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

		if [ ${length} -eq 22 ]; then
			echo "<dd><span class=\"offline\">Offline</span>&emsp;&emsp;&emsp;&emsp;$ip</dd>" >> ${cache_file}
		elif [ ${length} -eq 27 ]; then
			line="$( echo ${p[ $(expr ${length} - 2) ]} | cut -d/ -f2 ) ms"
			echo "<dd><span class=\"online\">$line</span>&emsp;&emsp;&emsp;&emsp;$ip&emsp;&emsp;&emsp;&emsp;$de</dd>" >> ${cache_file}
		else
			echo "<dd><span class=\"offline\">Error</span>&emsp;&emsp;&emsp;&emsp;$ip&nbsp;${p[*]}</dd>" >> ${cache_file}
		fi
		pos=$( expr $pos + 1 )
	done

	cat ${script_path}/tail.html >> ${cache_file}
	mv ${cache_file} ${output_file}

	sleep 5m

done


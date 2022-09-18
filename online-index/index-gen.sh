#!/bin/sh
##########################################################
#                 sakura-lan online-index                #
#                                                        #
# ping ip list in ip.json,                               #
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

set +e

script_path=$(cd $(dirname $0); pwd)
output_file=index.html
ips=$(jq -c ".ips" ${script_path}/ip.json | sed 's/[]",[]/ /g')

echo Scan IPs $ips

while true; do

	cat ${script_path}/head.html > ${output_file}
	echo "<dt>&nbsp;&nbsp;IP and ping status (F5 to refresh)</dt>" >> ${output_file}

	for i in $ips; do
		p=( $(ping -c 5 -w 5 -q $i 2>&1) )
		length=${#p[@]}
		# echo $lengh

		if [ ${length} -eq 22 ]; then
			echo "<dd><span class=\"offline\">Offline</span>&emsp;&emsp;&emsp;&emsp;$i</dd>" >> ${output_file}
		elif [ ${length} -eq 27 ]; then
			line="$( echo ${p[ $(expr ${length} - 2) ]} | cut -d/ -f2 ) ms"
			echo "<dd><span class=\"online\">$line</span>&emsp;&emsp;&emsp;&emsp;$i</dd>" >> ${output_file}
		else
			echo "<dd><span class=\"offline\">Error</span>&emsp;&emsp;&emsp;&emsp;$i&nbsp;${p[*]}</dd>" >> ${output_file}
		fi
	done

	sleep 15m

done

cat ${script_path}/tail.html >> ${output_file}


#!/bin/bash
#$1 func
#$2 device_name
#$3 rate_min
#$4 rate_max
#$5 port1
#$6、7、8...


function help() {
	echo "|  Usage: $0 limit|delete [device_name] [rate_min] [rate_max] [port1] ( [port2] [port3] [port4] )"
	echo "|  limit           : limit the device_name's Port with rate_min(bit/s) and rate_max(bit/s) [need all arguments] "
	echo "|  delete          : delete the limit rules [need device_name arguments]"
	echo "|  example         : ./limit limit eth0 1 2 8080 21 22"
}

function limit() {
	if [ $# -lt 5 ]
	then
		echo "----------------------arguments are not enough!----------------------"
		help
		exit 1
	fi
	read -r -p "limit $2 device with rate_min: $3Mbit/s and rate_max: $4Mbit/s at port $5 $6 $7 $8? [Y/n] " input
	case $input in
	    [yY][eE][sS]|[yY])
			;;
	    [nN][oO]|[nN])
			exit 0
	       	;;
	    *)
		echo "Invalid input"
		exit 1
		;;
	esac
	echo "building the $2 queue..."
    sudo tc qdisc add dev ${2} root handle 1: htb default 20
    echo "building the root class..."
    sudo tc class add dev ${2} parent 1:0 classid 1:1 htb rate ${4}Mbit
    echo "building the son class..."
    sudo tc class add dev ${2} parent 1:1 classid 1:20 htb rate ${3}Mbit ceil ${4}Mbit
    echo "adding the fair queue..."
    sudo tc qdisc add dev ${2} parent 1:20 handle 20: sfq perturb 10
    echo "building the class filter..."
    index=1
    for args in $*
    do
    	if [ $index -gt 5 ]
    	then
    		sudo tc filter add dev $2 parent 1:20 protocol ip u32 match ip sport $args 0xffff classid 1:20
		fi
		let index+=1
	done
	echo "------limit the bandwidth successfully!------"
}

function delete() {
	sudo tc qdisc del dev $1 root
	echo "------delete the rules successfully!------"
}

case "$1" in
	limit)
		limit $1 $2 $3 $4 $5 $6 $7 $8
		;;
	delete)
		delete $2
		;;
	*)
	echo -----------------------please read the Usage--------------------------
    help
    exit 1
esac

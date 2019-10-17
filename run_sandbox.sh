#!/bin/bash

user="--userspec=app"

cpu_period="-r cpu.cfs_period_us=100000"
cpu_quota="-r cpu.cfs_quota_us=100000"

cgroup_dir=$$

while :; do
	case $1 in
		--disable_network)
			network='--net'
		;;
		-u|--user)
			if [ "$2" ]; then
                user="--userspec=$2"
                shift
            else
                die 'ERROR: "--user" requires a non-empty option argument.'
            fi
		;;
		--user=?*)
			user="--userspec=${1#*=}"
		;;
		--cpu_period)
			if [ "$2" ]; then
                cpu_period="-r cpu.cfs_period_us=$2"
                shift
            else
                die 'ERROR: "--cpu_period" requires a non-empty option argument.'
            fi
		;;
		--cpu_period=?*)
			cpu_period="-r cpu.cfs_period_us=${1#*=}"
		;;
		--cpu_quota)
            if [ "$2" ]; then
                cpu_quota="-r cpu.cfs_quota_us=$2"
                shift
            else
                die 'ERROR: "--cpu_quota" requires a non-empty option argument.'
            fi
        ;;
		--cpu_quota=?*)
            cpu_quota="-r cpu.cfs_quota_us=${1#*=}"
        ;;
		--)
	    	shift
			dir=$1
			shift
			break
    	;;
    	\?) echo "Invalid option $1" >&2
    	;;
  	esac
  	shift
done

option=""
for arg in $@; do
	option+="${arg} "
done

printf "Argument network is %s\n" "$network"
printf "Argument dir is %s\n" "$dir"
printf "Argument user is %s\n" "$user"
printf "Argument option is %s\n" "$option"

sudo unshare $network --mount --fork bash -c "
	cgcreate -g cpu,memory,blkio,devices,freezer:/sandbox/$cgroup_dir
	cgset $cpu_period $cpu_quota sandbox/$cgroup_dir
	cgexec -g cpu,memory,blkio,devices,freezer:/sandbox/$cgroup_dir \
	chroot $user $dir $option
"

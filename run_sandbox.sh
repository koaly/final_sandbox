#!/bin/bash

user_t="--userspec=app"

cpu_period_t="-r cpu.cfs_period_us=100000"
cpu_quota_t="-r cpu.cfs_quota_us=10000"
memory_t="-r memory.limit_in_bytes=1G"

cgroup_dir=$$

while :; do
	case $1 in
		--disable_network)
			network='--net'
		;;
		-c|--config)
			if [ "$2" ]; then
                config="$2"
                shift
            else
                die 'ERROR: "--config" requires a non-empty option argument.'
            fi
		;;
		--config=?*)
			config="${1#*=}"
		;;
		-u|--user)
			if [ "$2" ]; then
                user="$2"
                shift
            else
                die 'ERROR: "--user" requires a non-empty option argument.'
            fi
		;;
		--user=?*)
			user="${1#*=}"
		;;
		--cpu_period)
			if [ "$2" ]; then
                cpu_period="$2"
                shift
            else
                die 'ERROR: "--cpu_period" requires a non-empty option argument.'
            fi
		;;
		--cpu_period=?*)
			cpu_period="${1#*=}"
		;;
		--cpu_quota)
            if [ "$2" ]; then
                cpu_quota="$2"
                shift
            else
                die 'ERROR: "--cpu_quota" requires a non-empty option argument.'
            fi
        ;;
		--cpu_quota=?*)
            cpu_quota="${1#*=}"
        ;;
		--memory)
            if [ "$2" ]; then
                memory="$2"
                shift
            else
                die 'ERROR: "--memory" requires a non-empty option argument.'
            fi
        ;;
		--memory=?*)
            memory="${1#*=}"
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

if [ "$config" ]; then
	. $config
fi

if [ "$disable_network" ]; then
	network='--net'
fi

if [ "$user" ]; then
	user_t="--userspec=$user"
fi

if [ "$cpu_period" ]; then
	cpu_period_t="-r cpu.cfs_period_us=$cpu_period"
fi

if [ "$cpu_quota" ]; then
	cpu_quota_t="-r cpu.cfs_quota_us=$cpu_quota"
fi

if [ "$memory" ]; then
	memory_t="-r memory.limit_in_bytes=$memory"
fi

option=""
for arg in $@; do
	option+="${arg} "
done

echo "****Please remember PID for sandbox monitoring.****"
echo "Sandbox's PID is "$BASHPID
echo "[Press any key to continue]"
read

# printf "Argument network is %s\n" "$network"
# printf "Argument dir is %s\n" "$dir"
# printf "Argument user is %s\n" "$user"
# printf "Argument option is %s\n" "$option"

sudo unshare $network --mount --fork bash -c "
	cgcreate -g cpu,memory,blkio,devices,freezer:/sandbox/$cgroup_dir
	cgset $cpu_period_t $cpu_quota_t $memory_t sandbox/$cgroup_dir
	cgexec -g cpu,memory,blkio,devices,freezer:/sandbox/$cgroup_dir \
	chroot $user_t $dir $option
"

#!/bin/bash

user="app"

io_read="1048576"
io_write="1048576"
cpu_period="100000"
cpu_quota="10000"
memory="1G"

cgroup_dir=$$

while :; do
	case $1 in
		--disable_network)
			disable_network="true"
		;;
		-n|--network)
			if [ "$2" ]; then
                network="$2"
                shift
            else
                die 'ERROR: "--network" requires a non-empty option argument.'
            fi
		;;
		--network=?*)
			network="${1#*=}"
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
		-m|--memory)
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
		--unlimit_io)
			unlimit_io='true'
		;;
		--io_read)
            if [ "$2" ]; then
                io_read="$2"
                shift
            else
                die 'ERROR: "--io_read" requires a non-empty option argument.'
            fi
        ;;
		--io_read=?*)
            io_read="${1#*=}"
        ;;
		--io_write)
            if [ "$2" ]; then
                io_write="$2"
                shift
            else
                die 'ERROR: "--io_write" requires a non-empty option argument.'
            fi
        ;;
		--io_write=?*)
            io_write="${1#*=}"
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

sandbox_ip=$((($$-1)/256)).$((($$-1)%256))
sudo ip netns add sandbox$$
sudo ip netns exec sandbox$$ ip addr add 127.0.0.1/8 dev lo
sudo ip netns exec sandbox$$ ip link set lo up
sudo ip link add veth$$ type veth peer name veth$$-in
sudo ip link set veth$$ up
sudo ip link set veth$$-in netns sandbox$$ up
sudo ip addr add 100.$sandbox_ip.1/30 dev veth$$
sudo ip netns exec sandbox$$ ip addr add 100.$sandbox_ip.2/30 dev veth$$-in
sudo ip netns exec sandbox$$ ip route add default via 100.$sandbox_ip.1 dev veth$$-in

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ext_if=$(ip route get 8.8.8.8 | grep 'dev' | awk '{ print $5 }')
sudo iptables -I POSTROUTING -t nat -s 100.$sandbox_ip.2/32 -o ${ext_if} -j MASQUERADE
sudo iptables -I FORWARD -i veth$$ -o ${ext_if} -j ACCEPT
sudo iptables -I FORWARD -i ${ext_if} -o veth$$ -j ACCEPT
sudo mkdir -p /etc/netns/sandbox$$

echo "****Please remember PID for sandbox monitoring.****"
echo "Sandbox's PID is "$BASHPID
echo nameserver 8.8.8.8 | sudo tee /etc/netns/sandbox$$/resolv.conf

if [ "$network" ]; then
	if [ $(head -1 $network) -eq 1 ]; then
	    sudo ip netns exec sandbox$$ iptables -A OUTPUT -d 8.8.8.8 -j ACCEPT; \
    	for addr in `tail -n +2 $network`; do \
        	sudo ip netns exec sandbox$$ iptables -A OUTPUT -d $addr -j ACCEPT; \
    	done
    	sudo ip netns exec sandbox$$ iptables -A OUTPUT -j DROP
	else
    	for addr in `tail -n +2 $network`; do \
        	sudo ip netns exec sandbox$$ iptables -A OUTPUT -d $addr -j DROP; \
    	done
	fi
fi

echo "[Press any key to continue]"
read

# printf "Argument network is %s\n" "$network"
# printf "Argument dir is %s\n" "$dir"
# printf "Argument user is %s\n" "$user"
# printf "Argument option is %s\n" "$option"

sudo cgcreate -g cpu,memory,blkio:/sandbox/$cgroup_dir
sudo cgset $cpu_period_t $cpu_quota_t $memory_t sandbox/$cgroup_dir

if [ "$disable_network" ]; then
	if [ "$unlimit_io" ]; then
		sudo unshare --net --mount --fork bash -c "
			cgexec -g cpu,memory:/sandbox/$cgroup_dir \
			chroot $user_t $dir $option
		"
	else
		sudo cat /proc/partitions | sed "s/ \+/ /g" | cut -d" " -f2,3 --output-delimiter=":" | grep "[0-9]" | while read dev; do sudo cgset -r blkio.throttle.read_bps_device="$dev $io_read" -r blkio.throttle.write_bps_device="$dev $io_write" sandbox/$cgroup_dir ; done
		sudo unshare --net --mount --fork bash -c "
			cgexec -g cpu,memory,blkio:/sandbox/$cgroup_dir \
			chroot $user_t $dir $option
		"
	fi
else
	if [ "$unlimit_io" ]; then
		sudo cgexec -g cpu,memory:/sandbox/$cgroup_dir \
			sudo ip netns exec sandbox$$ unshare --mount --fork bash -c "
			chroot $user_t $dir $option
		"
	else
		sudo cat /proc/partitions | sed "s/ \+/ /g" | cut -d" " -f2,3 --output-delimiter=":" | grep "[0-9]" | while read dev; do sudo cgset -r blkio.throttle.read_bps_device="$dev $io_read" -r blkio.throttle.write_bps_device="$dev $io_write" sandbox/$cgroup_dir ; done
		sudo cgexec -g cpu,memory,blkio:/sandbox/$cgroup_dir \
			sudo ip netns exec sandbox$$ unshare --mount --fork bash -c "
			chroot $user_t $dir $option
		"
	fi
fi

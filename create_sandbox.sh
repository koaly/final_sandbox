#!/bin/bash

user="app"

while :; do
	case $1 in
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
		-U|--update)
			update="update"
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

sandbox_name="$1"
user_dir="$sandbox_name/home/$user"

if [ "$config" ]; then
	. $config
fi

# echo $update
# echo $dir
# echo $sandbox_name

if [ "$update" ]; then
	sudo cp -r --no-dereference --preserve=mode,ownership,timestamps --verbose /{bin,dev,etc,lib,lib64,run,sbin,usr} $dir
	sudo rm -rf $dir/etc/resolv.conf
	echo nameserver 8.8.8.8 | sudo tee $dir/etc/resolv.conf
else
	mkdir $sandbox_name
	mkdir $sandbox_name/home
	mkdir $user_dir
	sudo cp -r --no-dereference --preserve=mode,ownership,timestamps --verbose $dir $user_dir
	sudo chown -R $user $user_dir
	sudo cp -r --no-dereference --preserve=mode,ownership,timestamps --verbose /{bin,dev,etc,lib,lib64,run,sbin,usr} $sandbox_name
	sudo rm -rf $sandbox_name/etc/resolv.conf
	echo nameserver 8.8.8.8 | sudo tee $sandbox_name/etc/resolv.conf
fi

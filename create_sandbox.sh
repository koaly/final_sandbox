#!/bin/bash

user=$USER

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
		-l|--update_lib)
			update_lib="true"
		;;
		-a|--update_app)
			update_app="true"
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

if [ "$config" ]; then
	. $config
fi

if [ $user == "root" ]; then
	user_dir="$sandbox_name/root"
else
	user_dir="$sandbox_name/home/$user"
fi

# echo $dir
# echo $sandbox_name

if [ "$update_lib" ]; then
	sudo cp -r --no-dereference --preserve=mode,ownership,timestamps --verbose /{bin,dev,etc,lib,lib64,run,sbin,usr} $dir
	sudo rm -rf $dir/etc/resolv.conf
	echo nameserver 8.8.8.8 | sudo tee $dir/etc/resolv.conf
elif [ "$update_app" ]; then
	mkdir $user_dir
	sudo cp -r --no-dereference --preserve=mode,ownership,timestamps --verbose $dir $user_dir
	sudo chown -R $user $user_dir
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

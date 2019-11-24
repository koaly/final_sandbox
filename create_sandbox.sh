#!/bin/bash

user="app"

while :; do
	case $1 in
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

# echo $update
# echo $dir
# echo $sandbox_name

if [ "$update" ]; then
	sudo cp -avr /{bin,dev,etc,lib,lib64,run,sbin,usr} $dir
else
	mkdir $sandbox_name
	mkdir $sandbox_name/home
	mkdir $user_dir
	cp -avr $dir $user_dir
	sudo chown -R $user $user_dir
	sudo cp -avrn /{bin,dev,etc,lib,lib64,run,sbin,usr} $sandbox_name
fi
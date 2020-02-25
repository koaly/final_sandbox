#!/bin/bash

printf "Select CONFIG FILE Mode [0 - Create|1 - Resource|2 - Network]: "
read mode

printf "Enter CONFIG FILE Location: "
read loc

echo > $loc

case $mode in
    0)
        read -p "Enter Application Owner <DEFAULT: $USER>: "
        if [ "$REPLY" ]; then
            echo "user=$REPLY" >> $loc
        fi
        echo "Enter Create/Update Mode [0 - Library|1 - Application|Others - Create]"
        read -p "<DEFAULT: Create>: "
        if [ "$REPLY" ]; then
            if [ $REPLY -eq 0 ]; then
                echo "update_lib=true" >> $loc
            elif [ $REPLY -eq 1 ]; then
                echo "update_app=true" >> $loc
            fi
        fi
    ;;
    1) 
        read -p "Enter Application Owner <DEFAULT: $USER>: "
        if [ "$REPLY" ]; then
            echo "user=$REPLY" >> $loc
        fi
        read -p "Enter CPU Peroid (us) <DEFAULT: 1000000>: "
        if [ "$REPLY" ]; then
            echo "cpu_period=$REPLY" >> $loc
        fi
        read -p "Enter CPU Quota in period (us) <DEFAULT: 100000>: "
        if [ "$REPLY" ]; then
            echo "cpu_quota=$REPLY" >> $loc
        fi
        read -p "Enter Memory Usage (byte) <DEFAULT: 2G>: "
        if [ "$REPLY" ]; then
            echo "memory=$REPLY" >> $loc
        fi
        read -p "Limit (ALL) Block I/O [Y|n]: "
        if [ $REPLY == "n" ]; then
            echo "unlimit_io=true" >> $loc
        else
            read -p "Enter Read I/O Rate (bps) <DEFAULT: 1048576>: "
            if [ "$REPLY" ]; then
               echo "io_read=$REPLY" >> $loc
            fi
            read -p "Enter Write I/O Rate (bps) <DEFAULT: 1048576>: "
            if [ "$REPLY" ]; then
               echo "io_write=$REPLY" >> $loc
            fi
        fi
        read -p "Select Network Mode [0 - Disable|1 - Limit|Others - Default]: "
        if [ $REPLY -eq 0 ]; then
            echo "disable_network=true" >> $loc
        elif [ $REPLY -eq 1 ]; then
            read -p "Enter Network Config File Location: "
            if [ "$REPLY" ]; then
               echo "network=$REPLY" >> $loc
            fi
        fi
    ;;
    2)
        read -p "Select Limit Network Mode [0 - Block|1 - Allow]: "
        if [ $REPLY -eq 1 ]; then
            echo "1" > $loc
        else
            echo "0" > $loc
        fi
        echo "Enter List of IP/DOMAIN (CTRL+C to Exit):" 
        while :
        do
	        read ip
            echo $ip >> $loc
        done
    ;;
    *) echo "Invalid option \"$mode\"" >&2
    ;;
esac

echo "Complete."


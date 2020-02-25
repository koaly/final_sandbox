#!/bin/bash

sleep_time=5
tree=0

while :; do
	case $1 in
		--tree)
			tree=1
		;;
		--export)
            if [ "$2" ]; then
                export_loc=$2
                shift
            else
                die 'ERROR: "--export" requires a non-empty option argument.'
            fi
        ;;
        --export=?*)
            export_loc=${1#*=}
		;;
		--time)
            if [ "$2" ]; then
                sleep_time=$2
                shift
            else
                die 'ERROR: "--time" requires a non-empty option argument.'
            fi
        ;;
		--time=?*)
            sleep_time=${1#*=}
        ;;
		--)
	    	shift
			sandbox_pid=$1
			shift
			break
    	;;
    	\?) echo "Invalid option $1" >&2
    	;;
  	esac
  	shift
done

if [ "$export_loc" ]; then
	echo Exporting log of Sandbox PID ${sandbox_pid} to ${export_loc}...
	while true; do
		if [ ${tree} == 1 ]; then
			echo ============================================= >> ${export_loc}
			date >> ${export_loc}
			echo Sandbox PID is ${sandbox_pid} >> ${export_loc}
			ps -o user,%cpu,%mem,cmd --forest -g $(ps -o sid= -p ${sandbox_pid}) >> ${export_loc}
			echo ============================================= >> ${export_loc}
			echo >> ${export_loc}
		else
			echo ============================================= >> ${export_loc}
			date >> ${export_loc}
			echo Sandbox PID is ${sandbox_pid} >> ${export_loc}
			ps -o user --forest -g $(ps -o sid= -p ${sandbox_pid}) | awk 'END {print "USER " $1}' >> ${export_loc}
			ps -o %cpu --forest -g $(ps -o sid= -p ${sandbox_pid}) | awk '{FS=" "}{s+=$1}END{print "%CPU " s}' >> ${export_loc}
			ps -o %mem --forest -g $(ps -o sid= -p ${sandbox_pid}) | awk '{FS=" "}{s+=$1}END{print "%MEM " s}' >> ${export_loc}
			echo ============================================= >> ${export_loc}
			echo >> ${export_loc}
		fi
		sleep ${sleep_time}
	done
else
	while true; do
		if [ ${tree} == 1 ]; then
			echo =============================================
			date
			echo Sandbox PID is ${sandbox_pid}
			ps -o user,%cpu,%mem,cmd --forest -g $(ps -o sid= -p ${sandbox_pid})
			echo =============================================
			echo
		else
			echo =============================================
			date
			echo Sandbox PID is ${sandbox_pid}
			ps -o user --forest -g $(ps -o sid= -p ${sandbox_pid}) | awk 'END {print "USER " $1}'
			ps -o %cpu --forest -g $(ps -o sid= -p ${sandbox_pid}) | awk '{FS=" "}{s+=$1}END{print "%CPU " s}'
			ps -o %mem --forest -g $(ps -o sid= -p ${sandbox_pid}) | awk '{FS=" "}{s+=$1}END{print "%MEM " s}'
			echo =============================================
			echo
		fi
		sleep ${sleep_time}
	done
fi

	

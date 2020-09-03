#!/bin/bash

KEEP_ENDS=true

while getopts "a" OPTION; do
	case $OPTION in
	a)
		KEEP_ENDS=false
		;;
	*)
		echo "Incorrect options provided"
		;;
	esac
done


if ! "${KEEP_ENDS}" ; then
	printf "Deleting all CHG, CHGCAR, and WAVECAR files ... "
	find . -type f \( -name CHGCAR -o -name CHG -o -name WAVECAR \) -delete
	printf "done\n"
else
	printf "Deleting all CHG, CHGCAR, and WAVECAR files, unless in 0_A or 8_A folders ... "
	# Wildcards in below command should be inside quotes, as find -path appears to use globbing, not regex
	find . -type f -not \( -path "*0_Ca*" -o -path "*8_Ca*" -o -path "*0_Mg*" -o -path "*8_Mg*" -o -path "*0_Zn*" -o -path "*8_Zn*" \) \( -name CHGCAR -o -name CHG -o -name WAVECAR \) -delete
	printf "done\n"
fi
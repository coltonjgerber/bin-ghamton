#!/bin/bash

FAST=false
while getopts "f" OPTION; do
	case $OPTION in
	f)  
		FAST=true
		shift
		;;
	*)
		echo "Incorrect options provided"
		;;
	esac
done

if [[ -e CHGCAR ]] && [[ -e WAVECAR ]] ; then
	if ! "${FAST}" ; then
		cp {INCAR,KPOINTS,CONTCAR,runVASP.sh,CHGCAR,WAVECAR} "${1}"
	else
		cp {INCAR,KPOINTS,CONTCAR,runVASP.sh} "${1}"
	fi
else
	cp {INCAR,KPOINTS,CONTCAR,runVASP.sh} "${1}"
fi
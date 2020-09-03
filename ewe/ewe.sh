#!/bin/bash

# Checks if reached required accuracy in slurm, if so, search backwards for ewe line, then remove front and back of line to get number, and add to list with folder number

source rerunVASP_functions.sh

FOLDER_CHECK=false
IS_NEB=false
PRIMITIVE_CELL=false
while getopts "fnp" OPTION; do
	case $OPTION in
	f)  # Instead of writing out to a spreadsheet, use the lowest_ion and lowest_ion_energy
		# variables to determine which ion has the lowest energy
		FOLDER_CHECK=true
		;;
	n)  ## DOES NOT WORK ########################
		IS_NEB=true 
		;;
	p)	# Make the size of the array/list of ions 2 instead of 8
		PRIMITIVE_CELL=true
		;;
	*)
		echo "Incorrect options provided"
		;;
	esac
done


if "${PRIMITIVE_CELL}" ; then
	size_array=( 1 2 )
else
	size_array=( 1 2 3 4 5 6 7 8 )
fi
for i in "${size_array[@]}" ; do
	ewe_array["${i}"]=""
done
find_folder_list
printf "Checking for folder list ... " >&3
if [[ -n "${folder_list}" ]] ; then
	printf "found folder list\n" >&3
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		printf "%s" "Checking name of folder ${folder_name} ... " >&3
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
			printf "OK\n" >&3
			cd "${folder}"
			find_slurm_and_job
			ewe_value=
			printf "%s" "Checking for completion in folder ${folder_name} ... " >&3
			if [[ $(grep 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}") ]] || "${IS_NEB}" ; then
				printf "OK\n" >&3
				ewe_value=$(tac $(find . -maxdepth 1 -mindepth 1 -name "OUTCAR") | grep -m 1 'energy  without entropy' || :)
				ewe_value="${ewe_value#'  energy  without entropy=     '}"
				ewe_value="${ewe_value%  energy*}"
				printf "%s\n" "Ewe value is : ${ewe_value}" >&3
			else
				printf "not completed\n" >&3
			fi
			cd ../
			ewe_array["${folder_name:0:1}"]="${ewe_value}"
		else
			printf "%s\n" "skipping folder" >&3
		fi
		printf "\n" >&3
	done < <(printf '%s\n' "${folder_list}")
	if ! "${FOLDER_CHECK}" ; then
		for i in "${size_array[@]}" ; do
			printf "%s %s\n" "${i}" "${ewe_array["${i}"]}" >> temp_spreadsheet
		done
	else
		lowest_ion=
		lowest_ion_energy=0
		for i in "${size_array[@]}" ; do
			#array_entry=$(echo "${ewe_array["${i}"]}" | awk '{printf "%.5f", $1;}') USE INSTEAD OF FOLLOWING LINE IF NEED TO HANDLE FLOATING POINT
			array_entry="${ewe_array["${i}"]}"
			if [[ -n "${array_entry}" ]] ; then
				if (( $(echo "${array_entry} < ${lowest_ion_energy}" | bc -l) )); then
					lowest_ion="${i}"
					lowest_ion_energy="${array_entry}"
				fi
			fi
		done
		printf "%s\n" "Lowest energy ion is: ${lowest_ion}" >&3
		printf "%s\n" "Lowest energy is: ${lowest_ion_energy}" >&3
		echo "${lowest_ion}"
	fi
else
	printf "no folders found\n" >&3
	ewe_value=
	find_slurm_and_job
	printf "Checking current folder for completion ... " >&3
	if [[ $(grep 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}") ]] || "${IS_NEB}" ; then
		printf "OK\n" >&3
		ewe_value=$(tac "$(find . -maxdepth 1 -mindepth 1 -name "OUTCAR")" | grep -m 1 'energy  without entropy' || :)
		ewe_value="${ewe_value#'  energy  without entropy=     '}"
		ewe_value="${ewe_value%  energy*}"
		printf "%s\n" "Ewe value is : ${ewe_value}" >&3
		if ! "${FOLDER_CHECK}" ; then
			printf "%s\n" "${ewe_value}" >> temp_spreadsheet
		else
			lowest_ion=
			lowest_ion_energy="${ewe_value}"
		fi
	fi
fi

if ! "${FOLDER_CHECK}" ; then
	column -t temp_spreadsheet > ewe_spreadsheet
	column -t temp_spreadsheet -o $'\t'
	rm temp_spreadsheet
fi

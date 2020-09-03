#!/bin/bash

# Checks if reached required accuracy in slurm, if so, search backwards for ewe line, then remove front and back of line to get number, and add to list with folder number

source rerunVASP_functions.sh

FOLDER_CHECK=false
IS_NEB=false
PRIMITIVE_CELL=false
skip_convergence_check=false
while getopts "fnpx" OPTION; do
	case $OPTION in
	f)  # Instead of writing out to a spreadsheet, use the lowest_ion and lowest_ion_energy
		# variables to determine which ion has the lowest energy
		FOLDER_CHECK=true
		;;
	n)  ## Instead of checking each folder for completed message in slurm file, check parent only
		IS_NEB=true
		echo "Set IS_NEB=true"
		;;
	p)	# Make the size of the array/list of ions 2 instead of 8
		PRIMITIVE_CELL=true
		;;
	x)
		skip_convergence_check=true
		echo "Set skip_convergence_check=true"
		;;
	*)
		echo "Incorrect options provided"
		;;
	esac
done

find_folder_list
folder_list="$(echo "$folder_list" | sort)"

if [[ -n "${folder_list}" ]] ; then
	find_slurm_and_job
	if "${IS_NEB}" && [[ $(grep 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}") ]] || "${skip_convergence_check}"; then
		neb_complete=true
		echo "Set neb_complete=true"
	fi

	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		if [[ ! "${folder}" == *slurm* ]]  ; then # && [[ ! "${folder}" == *run* ]]
			cd "${folder}"
			folder_name=$(basename "${folder}")
			find_slurm_and_job
			ewe_value=
			# printf "Checking complete or NEB complete ... "
			if [[ $(grep 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}" 2>/dev/null) ]] || "${neb_complete}" ; then
				# printf "complete\n"
				ewe_value=$(tac $(find . -maxdepth 1 -mindepth 1 -name "OUTCAR") | grep -m 1 'energy  without entropy' || :)
				ewe_value="${ewe_value#'  energy  without entropy=     '}"
				ewe_value="${ewe_value%  energy*}"
			fi
			cd ../
			printf "%s %s\n" "${folder_name}" "${ewe_value}" >> temp_spreadsheet
		else
			printf "%s\n" "Skipping folder ${folder_name}"
		fi
	done < <(printf '%s\n' "${folder_list}")
else
	find_slurm_and_job
	ewe_value=
	if [[ $(grep 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}") ]] ; then
		ewe_value=$(tac $(find . -maxdepth 1 -mindepth 1 -name "OUTCAR") | grep -m 1 'energy  without entropy' || :)
		ewe_value="${ewe_value#'  energy  without entropy=     '}"
		ewe_value="${ewe_value%  energy*}"
		printf "%s %s\n" "${ewe_value}" >> temp_spreadsheet
	fi
fi

column -t temp_spreadsheet > ewe_spreadsheet
column -t temp_spreadsheet -o $'\t'
rm temp_spreadsheet
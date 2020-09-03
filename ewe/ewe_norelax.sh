#!/bin/bash

# Searches slurm backwards for ewe line, then remove front and back of line to get number, and add to list with folder number. Does not check if reached required accuracy in slurm

source rerunVASP_functions.sh

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d)
if [[ -n "${folder_list}" ]] ; then
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		if [[ ! "${folder}" == *slurm* ]]  ; then # && [[ ! "${folder}" == *run* ]]
			cd "${folder}"
			folder_name=$(basename "${folder}")
			find_slurm_and_job
			ewe_value=
			#if [[ $(grep 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}") ]] ; then
				ewe_value=$(tac $(find . -maxdepth 1 -mindepth 1 -name "OUTCAR") | grep -m 1 'energy  without entropy' || :)
				ewe_value="${ewe_value#'  energy  without entropy=     '}"
				ewe_value="${ewe_value%  energy*}"
			#	fi
			cd ../
			printf "%s %s\n" "${folder_name}" "${ewe_value}" >> temp_spreadsheet
		else
			printf "%s\n" "Skipping folder ${folder_name}"
		fi
	done < <(printf '%s\n' "${folder_list}")
else
	printf "No folders found"
fi

column -t temp_spreadsheet > ewe_spreadsheet
column -t temp_spreadsheet
rm temp_spreadsheet
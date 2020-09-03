#!/bin/bash

# Checks if reached required accuracy in slurm, if so, search backwards for ewe line, then remove front and back of line to get number, and add to list with folder number

source rerunVASP_functions.sh

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d -not \( -name "*slurm*" -o -name "*run*" \))
ewe_array=
for i in 1 2 3 4 5 6 7 8 ; do
	ewe_array["${i}"]=""		
done

if [[ -n "${folder_list}" ]] ; then
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
			cd "${folder}"
			find_slurm_and_job
			ewe_value=
			if tac "${slurm_file}" | grep 'reached required accuracy - stopping structural energy minimisation' ; then
				ewe_value=$(tac $(find . -maxdepth 1 -mindepth 1 -name "OUTCAR") | grep -m 1 'energy  without entropy' || :)
				ewe_value="${ewe_value#'  energy  without entropy=     '}"
				ewe_value="${ewe_value%  energy*}"
			fi
			cd ../
			ewe_array["${folder_name:0:1}"]="${ewe_value}"
		else
			printf "%s\n" "Skipping folder ${folder_name}"
		fi
	done < <(printf '%s\n' "${folder_list}")
	for i in 1 2 3 4 5 6 7 8 ; do
		printf "%s %s\n" "${i}" "${ewe_array["${i}"]}" >> temp_spreadsheet
	done
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
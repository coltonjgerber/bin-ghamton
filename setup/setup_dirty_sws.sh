#!/bin/bash

source rerunVASP_functions.sh

setup_in_folder="${1}"

find_folder_list
if ls -la | grep -q "\->"; then # | awk '{print $11}' to get linked path
	# folder_list="$(echo "${folder_list}" ; find . -type l -exec readlink -f {} \;)"
	folder_list="$(echo "${folder_list}" ; find . -maxdepth 1 -type l )"
	echo "found a symlink"
fi

if [[ -n "${folder_list}" ]] ; then
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		# if [[ ! "${folder}" == *"data/home"* ]] ; then
			folder_name=$(basename "${folder}")
			ion_list=$(find ./"${folder_name}" -maxdepth 1 -mindepth 1 -type d -name "*lowest*")
		# else

		# fi
		
		if [[ -n "${ion_list}" ]] ; then
			ion_name=$(basename "${ion_list}")
			new_folder="${setup_in_folder}"/"${folder_name}"_"${ion_name}"
			mkdir "${new_folder}"
			printf "%s" "Copying files from ${folder_name}/${ion_name} to ${new_folder} ... "
			# rsync -q ./"${folder_name}"/"${ion_name}"/* ./DOS/"${folder_name}"_"${ion_name}"
			cd "${folder_name}"/"${ion_name}"
			cp_inputs.sh "${new_folder}"
			cd ../../
			printf "done\n"
		else
			( cd "${folder}"
			find_slurm_and_job
			if [[ -n "${slurm_file}" ]] ; then
				job_status=$(tac "${slurm_file}" | grep -q 'reached required accuracy - stopping structural energy minimisation' 2> /dev/null; echo $?)
					# echo "${job_status}"
				if [[ "${job_status}" == 141 ]] || [[ "${job_status}" == 0 ]]; then
					new_folder="${setup_in_folder}"/"${folder_name}"
					mkdir "${new_folder}"
					printf "%s" "Copying files from ${folder_name} to ${new_folder} ... "
					# rsync -q ./* ../DOS/"${folder_name}"
					cp_inputs.sh "${new_folder}" 
					printf "done\n"
				else
				printf "%s\n" "No clear lowest-energy structure in ${folder_name}"
				fi
			fi 
			)
		fi
	done < <(printf '%s\n' "${folder_list}")

	cd "${setup_in_folder}"
	find "${setup_in_folder}" -type f \( -name "*slurm*" -o -name "current_job" -o -name "ewe_spreadsheet" -o -name "error_list" \) -delete
	find_folder_list
	while IFS="" read -r folder || [ -n "${folder}" ]; do
		folder_name=$(basename "${folder}")
		cd "${folder}"
		mv CONTCAR POSCAR
		cd ..
	done <<< "${folder_list}"
else
 	printf "No viable folders found\n"
fi
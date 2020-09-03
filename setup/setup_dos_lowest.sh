#!/bin/bash

source rerunVASP_functions.sh
source verbose_mode.sh

find_folder_list

if [[ -n "${folder_list}" ]] ; then
	if [ ! -d ./DOS ] ; then
		mkdir DOS
	fi

	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		ion_list=$(find ./"${folder_name}" -maxdepth 1 -mindepth 1 -type d -name "*lowest*")
		if [[ -n "${ion_list}" ]] ; then
			ion_name=$(basename "${ion_list}")
			mkdir ./DOS/"${folder_name}"_"${ion_name}"
			printf "%s" "Copying files from ${folder_name}/${ion_name} to DOS ... "
			rsync -q ./"${folder_name}"/"${ion_name}"/* ./DOS/"${folder_name}"_"${ion_name}"
			printf "done\n"
		else
			( cd "${folder}"
			find_slurm_and_job
			if [[ -n "${slurm_file}" ]] ; then
				job_status=$(tac "${slurm_file}" | grep -q 'reached required accuracy - stopping structural energy minimisation' 2> /dev/null; echo $?)
					# echo "${job_status}"
				if [[ "${job_status}" == 141 ]] || [[ "${job_status}" == 0 ]]; then
					mkdir ../DOS/"${folder_name}"
					printf "%s" "Copying files from ${folder_name} to DOS ... "
					rsync -q ./* ../DOS/"${folder_name}"
					printf "done\n"
				else
				printf "%s\n" "No clear lowest-energy structure in ${folder_name}"
				fi
			fi 
			)
		fi
	done < <(printf '%s\n' "${folder_list}")

	find ./DOS -type f \( -name "*slurm*" -o -name "current_job" -o -name "error_list" \) -delete
	cd DOS
	find_folder_list
	while IFS="" read -r folder || [ -n "${folder}" ]; do
		folder_name=$(basename "${folder}")
		cd "${folder}"
		sed -i 's/NSW =.*$/NSW = 0/' INCAR
		printf "Changed NSW\n" >&3
		sed -i 's/#*LORBIT =.*[0-9]/LORBIT = 11/' INCAR
		printf "Changed LORBIT\n" >&3
		nedos_amt=5001
		nedos_amt=$(echo "${nedos_amt#"   number of dos      NEDOS =    "}" | sed 's/   number of ions     NIONS.*$//g')
		sed -i "/#*LASPH =.*$/a NEDOS = ${nedos_amt}" INCAR
		printf "Added NEDOS" >&3
		mv CONTCAR POSCAR
		cd ..
	done <<< "${folder_list}"
else
	printf "No viable folders found\n"
fi
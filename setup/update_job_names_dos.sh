#!/bin/bash

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d)
if [[ -n "${folder_list}" ]] ; then
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
			cd "${folder}"
			job_name=$(grep "${folder_name}" runVASP.sh 2> /dev/null || :)
			#if [[ -z "${job_name}" ]] ; then
				sed -i "s/\(#SBATCH -J.*\)/\1_DOS/" runVASP.sh
				printf "%s\n" "Changed runVASP job name in ${folder}"
			#fi
			cd ../
		else
			printf "%s\n" "Skipping folder ${folder_name}"
		fi
	done < <(printf '%s\n' "${folder_list}")
else
	printf "No folders found"
fi
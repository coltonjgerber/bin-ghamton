#!/bin/bash

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d)



printf "update_job_names.sh is checking for folders ... "
if [[ -n "${folder_list}" ]] ; then
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
			cd "${folder}"
			# job_name=$(grep "${folder_name}" runVASP.sh 2> /dev/null || :)
			#if [[ -z "${job_name}" ]] ; then
				sed -i "s/\(#SBATCH -J.*\)/\1${folder_name}/" runVASP.sh
				# printf "%s\n" "Changed runVASP job name in ${folder}"
			#fi
			cd ../
		else
			printf "%s" "skipping folder ${folder_name}"
		fi
	done < <(printf '%s\n' "${folder_list}")
	printf "changed runVASP.sh job names\n"
else

	printf "no folders found\n"
	printf "Checking for runVASP.sh ... "
	if [[ -e runVASP.sh ]] ; then
		printf "found runVASP.sh\n"
		curr_dir=$(basename "$(pwd)")
		curr_ion_amt="${curr_ion_amt#${parent_dir}}"
		curr_ion_amt="${curr_ion_amt:0:1}" # May need to edit if "/"" is still present in name
		sed -i "s/\(#SBATCH -J.*\)/\1${curr_ion_amt}/" runVASP.sh
		# printf "%s\n" "Changed runVASP job name in ${curr_dir}"
	else
		printf "no runVASP.sh file found"
	fi
fi

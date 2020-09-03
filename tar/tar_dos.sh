#!/bin/bash

source rerunVASP_functions.sh

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d -not \( -name "*slurm*" -o -name "*run*" -o -name "*DOS*" -o -name "*initial*" \))

if [[ -n "${folder_list}" ]] ; then
	curr_path=$(pwd)
	super_parent_dir=$(basename "$(dirname "$(dirname "${curr_path}")")")
	parent_dir=$(basename "$(dirname "${curr_path}")")
	tar_folder="${super_parent_dir}_${parent_dir}_doscars"
	mkdir "${tar_folder}"

	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
			( cd "${folder}"
				if [ -f DOSCAR ] ; then		
					printf "%s" "Copying DOSCAR from ${folder_name} ... "
					rsync -q ./DOSCAR ../"${tar_folder}"
					cd ../"${tar_folder}"
					mv DOSCAR "DOSCAR_${tar_folder}_${folder_name}"
					printf "done\n"
				else
				printf "%s\n" "No DOSCAR in ${folder_name}"
				fi
			)
	done < <(printf '%s\n' "${folder_list}")
	tar -czf "${tar_folder}.tar.gz" "${tar_folder}"
	rm -r "${tar_folder}"
else
	printf "No viable folders found\n"
fi
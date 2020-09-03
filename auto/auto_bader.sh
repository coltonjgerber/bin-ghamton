#!/bin/bash

set -e

source rerunVASP_functions.sh

if ! [ $# -eq 0 ]; then
	while :; do
		 case ${1-default} in
			# (-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
			# 	;; 
			(--) # End of all options.
				shift
				break
				;;
			(-?*)
				printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
				;;
			(*) # Default case: No more options, so break out of the loop.
				break
		 esac
		 shift
	done
fi

find_folder_list
symlink_list="$(find . -maxdepth 1 -mindepth 1 -type l)"
folder_list="$(echo "${folder_list}"; echo "${symlink_list}")"

if [[ -n "${folder_list}" ]] ; then
	if [ ! -d ./bader ] ; then
		mkdir bader
	fi

	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		ion_list=$(find -L ./"${folder_name}" -maxdepth 1 -mindepth 1 -type d -name "*lowest*")
		if [[ -n "${ion_list}" ]] ; then
			ion_name=$(basename "${ion_list}")
			if [ ! -d ./bader/"${folder_name}_${ion_name}" ] ; then
				mkdir ./bader/"${folder_name}"_"${ion_name}"
			fi
			printf "%s" "Copying files from ${folder_name}/${ion_name} to bader ... "
			rsync -q ./"${folder_name}"/"${ion_name}"/* ./bader/"${folder_name}"_"${ion_name}"
			printf "done\n"
		else
			actual_parent="$(pwd)"
			( cd "${folder}"
			find_slurm_and_job
			if [[ -n "${slurm_file}" ]] ; then
				job_status=$(tac "${slurm_file}" | grep -q 'reached required accuracy - stopping structural energy minimisation' 2> /dev/null; echo $?)
					# echo "${job_status}"
				if [[ "${job_status}" == 141 ]] || [[ "${job_status}" == 0 ]]; then
					if [ ! -d "${actual_parent}/bader/${folder_name}" ] ; then
						mkdir "${actual_parent}/bader/${folder_name}"
					fi
					printf "%s" "Copying files from ${folder_name} to bader ... "
					rsync -q ./* ../bader/"${folder_name}"
					printf "done\n"
				else
				printf "%s\n" "No clear lowest-energy structure in ${folder_name}"
				fi
			fi 
			)
		fi
	done < <(printf '%s\n' "${folder_list}")

	find ./bader -type f \( -name "*slurm*" -o -name "current_job" -o -name "error_list" -o -name "ion_list" -o -name "error_list" -o -name "CONTCAR.bk" \) -delete
	cd bader
	update_job_names_convergence.sh -a _bader
	find_folder_list
	while IFS="" read -r folder || [ -n "${folder}" ]; do
		folder_name=$(basename "${folder}")
		cd "${folder}"
		sed -i 's/NSW =.*$/NSW = 0/' INCAR
		printf "Changed NSW\n" >&3
		tmpfile=$(mktemp)
		cp INCAR "$tmpfile" && gawk -v nl="$(printf "%s\n" "LAECHG = True")" '/LCHARG/ {print; printf "%s\n",nl; next}1' "$tmpfile" >INCAR
		printf "Added LAECHG\n" >&3
		if [[ -e CONTCAR ]] ; then
			mv CONTCAR POSCAR
			printf "Replaced POSCAR with CONTCAR" >&3
		fi
		rerunVASP.sh
		cd ..
	done <<< "${folder_list}"
	(crontab -l ; echo "* * * * * cd $(pwd) && auto_bader_crontab.sh ${next_ion_amt} ${ion_element}") | awk '!x[$0]++' | crontab -
else
	printf "No viable folders found\n"
fi


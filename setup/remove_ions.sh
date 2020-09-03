#!/bin/bash

ion_element="${1}"

if ! { [[ "$(pwd)" == *[0-9]_Ca* ]] || [[ "$(pwd)" == *[0-9]_Mg* ]] || [[ "$(pwd)" == *[0-9]_Zn* ]]; } ; then
	next_ion_amt="$(basename "$(dirname "$(pwd)")")"
else
	next_ion_amt="$(basename "$(pwd)")"
fi
# ion_element="${curr_ion_amt:3:4}"
next_ion_amt="${next_ion_amt:0:1}"
curr_ion_amt=$(( next_ion_amt + 1 ))
if [[ "${curr_ion_amt}" == 0 ]] ; then
	echo "No ions left to remove"
	exit
fi

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d)
printf "remove_ions.sh is checking folders ... "
if [[ -n "${folder_list}" ]] ; then
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
			re='^[0-9]{1}$'
			folder_name="$(basename "${folder}")"
			if ! [[ "${folder_name}" =~ ${re} ]] ; then
				printf "ERROR: Folder name is not a single digit\n"
				exit
			fi
			cd "${folder}"
			sed -i "/# ${1} $(basename ${folder})/d" POSCAR
			if [[ "${next_ion_amt}" == 0 ]] ; then
				sed -i "6s/\s\{1,\}${ion_element}\s\{1,\}/\ \ \ /" POSCAR
				sed -i "7s/\s\{1,\}${curr_ion_amt}\s\{1,\}/\ \ \ \ \ /" POSCAR
			else
				sed -i "7s/\ ${curr_ion_amt}\ /\ ${next_ion_amt}\ /" POSCAR
			fi
			# tmpfile=$(mktemp)
			# cp POSCAR "$tmpfile" && gawk -v previonamt="${prev_ion_amt}" -v ionelement="${ion_element}" '
			# 	/ionelement / {
			# 		print; 
			# 		for (i = 1; i <= numions; i++) {
			# 			if (i in ionarray) {
			# 				getline;
			# 				printf "%s", $0;
			# 				printf "%s\n", " # " ionelement " " ionarray[i];
			# 			}
			# 		}
			# 	next}1' "$tmpfile" >POSCAR
			# printf "%s\n" "Changed POSCAR in ${folder}"
			cd ../
		else
			printf "%s" "skipping folder $(basename "${folder}") ... "
		fi
	done < <(printf '%s\n' "${folder_list}")
	printf "%s\n" "changed POSCARs"
else
	printf "no folders found\n"
fi

#!/bin/bash

source verbose_mode.sh

ion_element="${1}"

if ! { [[ "$(pwd)" == *[0-9]_Ca* ]] || [[ "$(pwd)" == *[0-9]_Mg* ]] || [[ "$(pwd)" == *[0-9]_Zn* ]]; } ; then
	next_ion_amt="$(basename "$(dirname "$(pwd)")")"
else
	next_ion_amt="$(basename "$(pwd)")"
fi
next_ion_amt="${next_ion_amt:0:1}"
curr_ion_amt=$(( next_ion_amt - 1 ))
if [[ "${curr_ion_amt}" == 8 ]] ; then
	echo "No ions left to add"
	exit
fi

ion_list="  0.2500000000000000  0.2500000000000000  0.7500000000000000 # ${ion_element} 1
  0.0000000000000000  0.0000000000000000  0.5000000000000000 # ${ion_element} 2
  0.2500000000000000  0.7500000000000000  0.2500000000000000 # ${ion_element} 3
  0.0000000000000000  0.5000000000000000  0.0000000000000000 # ${ion_element} 4
  0.7500000000000000  0.2500000000000000  0.2500000000000000 # ${ion_element} 5
  0.5000000000000000  0.0000000000000000  0.0000000000000000 # ${ion_element} 6
  0.7500000000000000  0.7500000000000000  0.7500000000000000 # ${ion_element} 7
  0.5000000000000000  0.5000000000000000  0.5000000000000000 # ${ion_element} 8
  "

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d)
printf "add_ions.sh is checking for folders ... "
if [[ -n "${folder_list}" ]] ; then
	printf "found folders\n" >&3
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		printf "%s" "Checking folder name ${folder_name} ... " >&3
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
			re='^[0-9]{1}$'
			if ! [[ "${folder_name}" =~ ${re} ]] ; then
				printf "ERROR: Folder name is not a single digit\n"
				exit 1
			fi
			cd "${folder}"
			if [[ "${curr_ion_amt}" == 0 ]] ; then
				sed -i "6s/\(\s\{1,\}Mn\s\{1,\}\)/\ \ \ ${ion_element}\1/" POSCAR
				sed -i "7s/\(\s\{1,\}16\s\{1,\}\)/\ \ \ \ \ ${next_ion_amt}\1/" POSCAR
			else
				sed -i "7s/\ ${curr_ion_amt}\ /\ ${next_ion_amt}\ /" POSCAR
			fi
			ion_array=()
			current_ions=$(grep "# ${ion_element}" POSCAR)

			if [[ -n "${current_ions}" ]] ; then
				# Commented out for testing while loop, delete if while loop works
				# for line in "${current_ions}" ; do
				# 	ion_number="${line: -1}"
				# 	echo "Adding to array current ion: ${ion_number}"
				# 	# echo "Line being added is: ${line}"
				# 	ion_array[${ion_number}]="${line}"
				# done
				while IFS="" read -r line || [ -n "${line}" ]; do
				    ion_number="${line: -1}"
				    echo "Adding to array current ion: ${ion_number}" >&3
				    ion_array[${ion_number}]="${line}"
				done <<< "${current_ions}"
			fi
			printf "%s\n" "Current number of ions: ${#ion_array[@]}" >&3


			insert_line=$(echo "${ion_list}" | grep "# ${ion_element} ${folder_name}")
			# echo "Line to be inserted is: ${insert_line}"
			ion_array[${folder_name}]="${insert_line}"
			printf "%s\n" "Updated number of ions: ${#ion_array[@]}" >&3
			# printf "%s\n" "Ion array using @ is: ${ion_array[@]}"

			# Read array into string, delete old ions from POSCAR, make a temporary file, add ions back to temporary file, and replace POSCAR with the edited temporary file.
			IFS='\n';new_ions="${ion_array[@]}"
			sed -i "/# ${ion_element} /d" POSCAR		
			tmpfile=$(mktemp)
			cp POSCAR "$tmpfile" && gawk -v ia="$(printf "%s\n" "${ion_array[@]}")" '/Direct/ {print; printf "%s\n",ia; next}1' "$tmpfile" >POSCAR	
			rm "$tmpfile"
			printf "%s\n" "Changed POSCAR in ${folder}" >&3
			cd ../
		else
			printf "%s\n" "skipping folder ${folder} ... "
		fi
	done < <(printf '%s\n' "${folder_list}")
	printf "changed POSCARs in folders\n"
else
	printf "no folders found" >&3
fi
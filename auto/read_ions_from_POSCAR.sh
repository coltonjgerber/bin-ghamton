#!/bin/bash


is_empty=false

# Below conditional should only be followed when called by continueVASP. auto_chg.sh should already have ion_element set.
if ! [ ${ion_element+passedifexists} ]; then
	printf "Identifying ion element from POSCAR\n"
	ion_element=$(grep -m 1 "[0-9] # [A-Z][a-z]" POSCAR || :)
	if [[ -n "${ion_element}" ]] ; then	
		ion_element="${ion_element: -4}"
		ion_element="${ion_element:0:2}"
	elif { [[ "$(pwd)" == *0_Ca* ]] || [[ "$(pwd)" == *0_Mg* ]] || [[ "$(pwd)" == *0_Zn* ]]; } ; then
		is_empty=true
	fi
fi

if ! "${is_empty}" ; then
	# Below lines are from add_ions.sh
	ion_array=()
	current_ions=$(grep "# ${ion_element}" POSCAR)
	if [[ -e ion_list ]] ; then
		rm ion_list
	fi
	while IFS="" read -r line || [ -n "${line}" ]; do
	    ion_number="${line: -1}"
	    echo "Adding to array current ion: ${ion_number}" >&3
	    ion_array[${ion_number}]="${line}"
	    echo "${ion_number}" >> ion_list
	done <<< "${current_ions}"
	# Above lines are from add_ions.sh
fi

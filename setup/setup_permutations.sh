#!/bin/bash

permutation_list=$(grep -v "^$" permutations)

while IFS="" read -r permutation || [ -n "${permutation}" ] ; do
	# Make folder for all permutations with certain number of atoms
	permutation_length=${#permutation}
	((permutation_length = 8 - permutation_length))
	ion_folder="${permutation_length}_${1}"
	folder_check=$(find . -maxdepth 1 -mindepth 1 -type d -name "${ion_folder}")
	if [[ -z "${folder_check}" ]] ; then
		mkdir "${ion_folder}"
	fi

	# Read each number in permutation into permutation_array
	permutation_list=$(echo "${permutation}" | grep -o .)  # return each atom number of permutation on different line
	permutation_array=
	unset permutation_array
	while IFS= read -r line || [ -n "${line}" ]
	do
		permutation_array+=("${line}")
	done < <(printf '%s\n' "${permutation_list}")

	# Make folder for permutation and copy input files to folder
	#IFS='_';permutation_folder="${permutation_array[*]// /|}"
	mkdir "${ion_folder}/${permutation}"
	cp {POSCAR,INCAR,runVASP.sh,KPOINTS,CHGCAR,WAVECAR} "${ion_folder}/${permutation}"
	
	# Replace number of ions (MUST BE ON LINE 7) with permutation_length (8 - actual permutation length)
	cd "${ion_folder}/${permutation}"
	sed -i "7s/8/${permutation_length}/" POSCAR

	sed -i "s/\(#SBATCH -J.*\)/\1${permutation}/" runVASP.sh  # update job name

	# Remove ion numbers in permutation_array from POSCAR
	for ion in "${permutation_array[@]}"; do
		echo "Removing ion ${ion}"
		sed -i "/# ${1} ${ion}/d" POSCAR
	done
	printf "%s\n" "Set up ${ion_folder}/${permutation}"
	
	cd ../../

done < <(printf '%s\n' "${permutation_list}")
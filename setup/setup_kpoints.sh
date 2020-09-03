#!/bin/bash

i="${1}"
while [[ ! "${i}" -gt "${2}" ]] ; do
	new_folder="${i}_${i}_${i}_KP"
	mkdir "${new_folder}" 2> /dev/null || (rm -r "${new_folder}" && mkdir "${new_folder}") 
	cp {INCAR,POSCAR,runVASP.sh} "${new_folder}"
	cd "${new_folder}"
	cat > KPOINTS <<-EOL
	K-Points
	0
	Gamma
	 ${i}	${i}	${i}
	 0	0	0
	EOL
	printf "%s\n" "Made folder ${new_folder}"
	((i=i+1))
	cd ../
done

update_job_names_convergence.sh
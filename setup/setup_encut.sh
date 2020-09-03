#!/bin/bash

i="${1}"
while [[ ! "${i}" -gt "${2}" ]] ; do
	new_folder="${i}_encut"
	mkdir "${new_folder}" 2> /dev/null || (rm -r "${new_folder}" && mkdir "${new_folder}")
	cp {INCAR,POSCAR,runVASP.sh,KPOINTS} "${new_folder}"
	cd "${i}_encut"
	sed -i -r "s/ENCUT = [0-9]+/ENCUT = ${i}/" INCAR
	printf "%s\n" "Made folder ${new_folder}"
	((i=i+50))
	cd ../
done

update_job_names_convergence.sh
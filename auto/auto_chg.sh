#!/bin/bash

set -e

source rerunVASP_functions.sh
source verbose_mode.sh

is_continuous=false
while :; do
	 case $1 in
		(--cont|--continuous)
			is_continuous=true
			;;
		(-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
			;; 
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

# Positional parameters (arguments): 
# $1 is the number of ions currently in the cell (8, if starting with a full multivalent spinel supercell). IF MORE THAN 8 IONS ARE INTERCALATED, CODE BELOW (size_array) WILL NEED TO BE CHANGED, AS WILL (MOST LIKELY) ewe.sh, remove_ions.sh, and label_ions.sh
# $2 is the species/element of the intercalated ion (Ca, Mg, etc.)
# $3 (not yet implemented) will be number of ions to take out at a time.

num_ions="${1}"
ion_element="${2}"

# Gives the option to run auto_chg from a "charging" folder, with input files (INCAR, POSCAR or CONTCAR, KPOINTS) present (except POTCAR, which will be created by rerunVASP)
if ! { [[ "$(pwd)" == *[0-9]_Ca* ]] || [[ "$(pwd)" == *[0-9]_Mg* ]] || [[ "$(pwd)" == *[0-9]_Zn* ]]; } ; then
	next_ion_amt=$(( num_ions - 1 ))
	mkdir "${next_ion_amt}_${ion_element}"
	cp ./* "${next_ion_amt}_${ion_element}" 2>/dev/null || :
	rm CHGCAR CONTCAR INCAR KPOINTS POSCAR runVASP.sh WAVECAR 2>/dev/null || :
	cd "${next_ion_amt}_${ion_element}"
	if [[ -e CONTCAR ]] ; then
		mv CONTCAR POSCAR
	fi
	label_ions.sh -s "${num_ions}" "${ion_element}" POSCAR
	source read_ions_from_POSCAR.sh
else
	# Below lines are partly from rerun_functions.sh
	crontab -l | grep -v "$(pwd)" | crontab -
	printf "%s\n" "Removed auto charge in $(pwd) from crontab"
	# Above lines are partly from rerun_functions.sh
	# curr_ion_amt="$(basename "$(pwd)")"
	# echo "curr ion amt before change: $curr_ion_amt"
	# curr_ion_amt="${curr_ion_amt:0:1}"
	# echo "curr ion amt after change: $curr_ion_amt"
	lowest_ion="$(ewe.sh -f)"
	mv "${lowest_ion}" "${lowest_ion}"_lowest
	printf "Checking if cell already empty ... " >&3

	if [[ "${num_ions}" == 0 ]]; then
		printf "already empty\n" >&3
		if "${is_continuous}"; then
			cd "${lowest_ion}"_lowest
			for ((i = 1 ; i <= 1000 ; i++)); do
				if [[ -z $(find ../../../ -maxdepth 1 -mindepth 1 -type d -name "*${i}auto*") ]]; then
					new_auto_folder="${i}auto_dis"
					mkdir "../../../${new_auto_folder}"
					printf "%s\n" "Made new auto folder ${new_auto_folder}"
					printf "Copying input files ... " >&3
					cp_inputs.sh -f "../../../${new_auto_folder}"
					printf "done\n" >&3
					break
				fi
				printf "%s" "${i}auto already exists ... " >&3 # If a profile (e.g. 4auto) does not already exist, the loop should break before this command in the previous if statement
#				if [[ "${i}" == 10 ]]; then
#					printf "10 half-cycles completed, stopping automatic cycling\n"
#					exit
				fi
			done
			cd ../../
		else
			cd ../
		fi

		mailx -s "Auto charge finished" "${USER}@binghamton.edu" <<-EOF
			Completed auto charge in: $(pwd)
			EOF
		parameters_lowest.py CONTCAR || :
		tar_lowest.py CONTCAR || :
		if "${is_continuous}" ; then
			previous_auto_folder=$(basename "$(pwd)")
			cd "../${new_auto_folder}"
			ln -s "../${previous_auto_folder}/0_Mg" "0_Mg_from_${previous_auto_folder}" || :
			auto_dis.sh --continuous 0 "${ion_element}"
		fi
		exit
	else
		printf "not empty\n" >&3
	fi

	cd "${lowest_ion}"_lowest
	source read_ions_from_POSCAR.sh
	cp CONTCAR CONTCAR.bk
	label_ions.sh 8 "${ion_element}" CONTCAR

	next_ion_amt=$(( num_ions - 1 ))
	mkdir ../../"${next_ion_amt}_${ion_element}"
	cp_inputs.sh -f ../../"${next_ion_amt}_${ion_element}"
	cd ../../"${next_ion_amt}_${ion_element}"
	mv CONTCAR POSCAR
fi

sed -i "s/\(#SBATCH -J.*\)/#SBATCH -J ${ion_element}_auto_chg_${next_ion_amt}-/" runVASP.sh

size_array=( 1 2 3 4 5 6 7 8 )
for i in "${size_array[@]}" ; do
	if [ ${ion_array["${i}"]+abcdefg} ]; then
		mkdir "${i}"
		cp ./* "${i}" 2>/dev/null || :
	fi
done

rm ./* 2>/dev/null || :
remove_ions.sh "${ion_element}"
update_job_names.sh
rerunVASP.sh --auto

if "${is_continuous}" ; then
	(crontab -l ; echo "* * * * * cd $(pwd) && auto_crontab.sh --continuous -c ${next_ion_amt} ${ion_element}") | awk '!x[$0]++' | crontab -
else
	(crontab -l ; echo "* * * * * cd $(pwd) && auto_crontab.sh -c ${next_ion_amt} ${ion_element}") | awk '!x[$0]++' | crontab -
fi
printf "%s\n" "Added auto charge to crontab in $(pwd)"



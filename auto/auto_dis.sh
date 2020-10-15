#!/bin/bash

set -e

source rerunVASP_functions.sh
source verbose_mode.sh

is_continuous=false
while :; do
	case $1 in
	--cont | --continuous)
		is_continuous=true
		;;
	--plusU)
		is_plus_u=true
		;;
	--prim | --primitive)
		is_primitive=true
		full_cell_num_ions=2
		;;
	--sd)
		is_selective_dynamics=true
		;;
	-v | --v | --ve | --ver | --verb | --verbo | --verbos | --verbose) ;;

	--) # End of all options.
		shift
		break
		;;
	-?*)
		printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
		;;
	*) # Default case: No more options, so break out of the loop.
		break ;;
	esac
	shift
done

# Positional parameters (arguments):
# $1 is the number of ions currently in the cell (0, if starting from the beginning). IF MORE THAN 8 IONS WILL EVENTUALLY BE INTERCALATED, CODE BELOW (size_array) WILL NEED TO BE CHANGED, AS WILL (MOST LIKELY) ewe.sh, remove_ions.sh, and label_ions.sh
# $2 is the species/element of the intercalated ion (Ca, Mg, etc.)
# $3 (not yet implemented) will be number of ions to put in at a time.

num_ions="${1}"
ion_element="${2}"


# Gives the option to run auto_dis.sh from a "discharging" folder, with input files ((INCAR, POSCAR or CONTCAR, KPOINTS) present (except POTCAR, which will be created by rerunVASP).
if ! { [[ "$(pwd)" == *[0-9]_Ca* ]] || [[ "$(pwd)" == *[0-9]_Mg* ]] || [[ "$(pwd)" == *[0-9]_Zn* ]]; } ; then
	next_ion_amt=$(( num_ions + 1 ))
	mkdir "${next_ion_amt}_${ion_element}"
	cp ./* "${next_ion_amt}_${ion_element}" 2>/dev/null || :
	rm CHGCAR CONTCAR INCAR KPOINTS POSCAR runVASP.sh WAVECAR 2>/dev/null || :
	cd "${next_ion_amt}_${ion_element}"
	if [[ -e CONTCAR ]] ; then
		mv CONTCAR POSCAR
	fi
else
	# Below lines are partly from rerun_functions.sh
	crontab -l | grep -v "$(pwd)" | crontab -
	printf "%s\n" "Removed auto discharge in $(pwd) from crontab"
	# Above lines are partly from rerun_functions.sh
	# curr_ion_amt="$(basename "$(pwd)")"
	# echo "curr ion amt before change: $curr_ion_amt"
	# curr_ion_amt="${curr_ion_amt:0:1}"
	# echo "curr ion amt after change: $curr_ion_amt"
	lowest_ion="$(ewe.sh -f)"
	mv "${lowest_ion}" "${lowest_ion}"_lowest
	printf "%s\n" "Changed name of folder ${lowest_ion} to ${lowest_ion}_lowest"

	cd "${lowest_ion}"_lowest
	source read_ions_from_POSCAR.sh
	cp CONTCAR CONTCAR.bk
	label_ions.sh 8 "${ion_element}" CONTCAR

	printf "Checking if cell already full ... " >&3
	if [[ "${num_ions}" == 8 ]]; then
		printf "already full\n" >&3
		if "${is_continuous}"; then
			for ((i = 1; i <= 1000; i++)); do
				if [[ -z $(find ../../../ -maxdepth 1 -mindepth 1 -type d -name "*${i}auto*") ]]; then
					new_auto_folder="${i}auto_chg"
					mkdir "../../../${new_auto_folder}"
					printf "%s\n" "Made new auto folder ${new_auto_folder}"
					printf "Copying input files ... " >&3
					cp_inputs.sh -f "../../../${new_auto_folder}"
					printf "done\n" >&3
					break
				fi
				printf "%s" "${i}auto already exists ... " >&3 # If a profile (e.g. 4auto) does not already exist, the loop should break before this command in the previous if statement
			done
		fi
		cd ../../
		mailx -s "Auto discharge finished" "${USER}@binghamton.edu" <<-EOF
			Completed auto discharge in: $(pwd)
			EOF
		parameters_lowest.py CONTCAR || :
		tar_lowest.py CONTCAR || :
		if "${is_continuous}" ; then
			previous_auto_folder=$(basename "$(pwd)")
			cd "../${new_auto_folder}"
			ln -s "../${previous_auto_folder}/8_Mg" "8_Mg_from_${previous_auto_folder}" || :
			auto_chg.sh --continuous 8 "${ion_element}"
		fi
		exit
	else
		printf "not empty\n" >&3
	fi

	next_ion_amt=$(( num_ions + 1 ))
	mkdir ../../"${next_ion_amt}_${ion_element}"
	cp_inputs.sh -f ../../"${next_ion_amt}_${ion_element}"
	cd ../../"${next_ion_amt}_${ion_element}"
	mv CONTCAR POSCAR
fi

sed -i "s/\(#SBATCH -J.*\)/#SBATCH -J ${ion_element}_auto_dis_${next_ion_amt}-/" runVASP.sh

size_array=( 1 2 3 4 5 6 7 8 )
for i in "${size_array[@]}" ; do
	if ! [ ${ion_array["${i}"]+abcdefg} ]; then
		mkdir "${i}"
		cp ./* "${i}" 2>/dev/null || :
	fi
done

rm ./* 2>/dev/null || :
add_ions.sh "${ion_element}" || exit 1
update_job_names.sh
rerunVASP.sh --auto

if "${is_continuous}" ; then
	(crontab -l ; echo "* * * * * cd $(pwd) && auto_crontab.sh --continuous -d ${next_ion_amt} ${ion_element}") | awk '!x[$0]++' | crontab -
else
	(crontab -l ; echo "* * * * * cd $(pwd) && auto_crontab.sh -d ${next_ion_amt} ${ion_element}") | awk '!x[$0]++' | crontab -
fi
printf "%s\n" "Added auto discharge to crontab in $(pwd)"



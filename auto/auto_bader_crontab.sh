#!/bin/bash

set -e

source rerunVASP_functions.sh

if ! [ $# -eq 0 ]; then
	# Options must be included separately, e.g. -c -v, and NOT -cv
	while :; do
		 case $1 in
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
fi

auto_crontab_ion_element="${2}"
auto_crontab_num_ions="${1}"

find_folder_list
# printf "Checking for folders ... "
if [[ -n "${folder_list}" ]] ; then
	# printf "found folders\n"
	# printf "Checking if calculations finished in folders ... "
	if check_folders_finished ; then
		# printf "calculations finished in folders\n"
		while IFS="" read -r folder || [ -n "${folder}" ] ; do
			cd "${folder}"
			chgsum.pl AECCAR0 AECCAR2
			bader CHGCAR -ref CHGCAR_sum
			species="$(grep "TITEL" POTCAR | sed 's/   TITEL  = PAW_PBE /""/')"
			if [ "${num_species}" -eq 2 ] ; then
				grep -o ""
			elif [ "${num_species}" -eq 3 ] ; then
			fi
			cd ..
		done < <(printf '%s\n' "${folder_list}")
	fi
else
	# printf "no appropriate folders found\n"
	find_slurm_and_job
	# printf "Checking to see if slurm file exists ... "
	if [[ -n "${slurm_file}" ]] ; then
		# printf "slurm found\n"
		# printf "Checking slurm to see if finished ... "
		if [[ $(grep 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}") ]] ; then
			# printf "calculation finished\n"
			auto_chg.sh "${auto_crontab_num_ions}" "${auto_crontab_ion_element}"
			fi
		fi
	fi
fi
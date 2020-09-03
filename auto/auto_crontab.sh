#!/bin/bash

set -e

source rerunVASP_functions.sh

profile_type=
is_continuous=false
# Options must be included separately, e.g. -c -v, and NOT -cv
while :; do
	 case $1 in
	 	(-c|--charge)
	 		profile_type="charge"
	 		;;
		(--cont|--continuous)
			is_continuous=true
			;;
		(-d|--discharge)
			profile_type="discharge"
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

auto_crontab_ion_element="${2}"
auto_crontab_num_ions="${1}"

find_folder_list
# printf "Checking for folders ... "
if [[ -n "${folder_list}" ]] ; then
	# printf "found folders\n"
	# printf "Checking if calculations finished in folders ... "
	if check_folders_finished ; then
		# printf "calculations finished in folders\n"
		if [[ "${profile_type}" == "charge" ]] ; then
			if "${is_continuous}" ; then
				auto_chg.sh --continuous "${auto_crontab_num_ions}" "${auto_crontab_ion_element}"
			else
				auto_chg.sh "${auto_crontab_num_ions}" "${auto_crontab_ion_element}"
			fi
		elif [[ "${profile_type}" == "discharge" ]] ; then
			if "${is_continuous}" ; then
				auto_dis.sh --continuous "${auto_crontab_num_ions}" "${auto_crontab_ion_element}"
			else
				auto_dis.sh "${auto_crontab_num_ions}" "${auto_crontab_ion_element}"
			fi
		else
			echo "Profile type not set"
			exit 1
		fi
	# else
		# printf "not finished\n"
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
			if [[ "${profile_type}" == "charge" ]] ; then
				auto_chg.sh "${auto_crontab_num_ions}" "${auto_crontab_ion_element}"
			elif [[ "${profile_type}" == "discharge" ]] ; then
				auto_dis.sh "${auto_crontab_num_ions}" "${auto_crontab_ion_element}"
			else
				echo "Profile type not set"
				exit 1
			fi
		fi
	fi
fi
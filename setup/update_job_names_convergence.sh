#!/bin/bash



die() {
	printf '%s\n' "${1}" >&2
	exit 1
}

string_to_add=
while :; do
	 case $1 in
		(-a|--add)
			 if [ "${2}" ] ; then 
			 	string_to_add="${2}"
			 	shift
			 else
			 	die 'ERROR: "--add" requires a non-empty option argument.'
			 fi
			 ;;
		(--)              # End of all options.
			 shift
			 break
			 ;;
		(-?*)
			 printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			 ;;
		(*)               # Default case: No more options, so break out of the loop.
			 break
	 esac
	 shift
done

folder_list=$(find . -maxdepth 1 -mindepth 1 -type d)
if [[ -n "${folder_list}" ]] ; then
	while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
			cd "${folder}"
			if [[ -n "${string_to_add}" ]] ; then
				sed -i "s/\(#SBATCH -J.*\)/\1${string_to_add}/" runVASP.sh
				printf "%s\n" "Changed runVASP job name in ${folder}"
			else
				job_name=$(grep "${folder_name}" runVASP.sh 2> /dev/null || :)
				if [[ -z "${job_name}" ]] ; then
					sed -i "s/\(#SBATCH -J.*\)/\1${folder_name}/" runVASP.sh
					printf "%s\n" "Changed runVASP job name in ${folder}"
				fi
			fi

			cd ../
		else
			printf "%s\n" "Skipping folder ${folder_name}"
		fi
	done < <(printf '%s\n' "${folder_list}")
else
	printf "No folders found"
fi
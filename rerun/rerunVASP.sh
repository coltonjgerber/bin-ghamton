#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

# Options must be included separately, e.g. -c -v, and NOT -cv
# while :; do
# 	 case $1 in
# 	 	(-a|--auto)
# 	 		suppress_individual_emails=true
# 	 		suppress_emails_option="--auto"
# 	 		;;
# 		# (-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
# 		# 	;;
# 		(--) # End of all options.
# 			shift
# 			break
# 			;;
# 		(-?*)
# 			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
# 			;;
# 		(*) # Default case: No more options, so break out of the loop.
# 			break
# 	 esac
# 	 shift
# done

source rerun_functions.sh # make functions (stored in another file) available for use

find_slurm_and_job # finds slurm-xxxxxxxx.out and current_job files, for use in checking if job is running, encountered
# an error, got stuck or ran out of steps.
find_folder_list # Finds list of folders not containing "slurm" or "run", if any
conditional_run # If running, do nothing. If done, check for an error or see if it got stuck. If no current_job file
# found, check if slurm file found. If slurm found, check if error or got stuck. If no slurm found, check for input
# files. If input files found, submit calculation. If no input files found, check folders (if "slurm" or "run" not in
# folder title)

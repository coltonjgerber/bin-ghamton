#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

source rerun_functions.sh # make functions shared with rerunNEB available for use

# Submit job and catch output to grab job number, then send output to stdout
run_and_catch_job() {
	if [[ -e ./POTCAR ]] ; then rm POTCAR ; fi
	potcar.sh
	sed -i 's/.*--exclude.*/'"$(cat ~/bin/exclude_list)"'/' runVASP.sh
	sbatch_output=$(sbatch runVASP.sh)
	printf "%s\n" "${sbatch_output}"
	printf "%s" "${sbatch_output#'Submitted batch job '}" > current_job
}

# WARNING: if you cancel a calculation, IMMEDIATELY use crontab -e to edit your crontab file and remove the line corresponding to the calculation you cancelled. Otherwise, crontab will keep trying to execute the script and will either restart the calculation or (more likely) fill up your mailbox with error messages.
# Adds a line to crontab to excute rerunVASP (check if running or stopped) every minute. 
# add_to_crontab() {
# 	(crontab -l ; echo "* * * * * cd $(pwd) && rerunVASP.sh") | awk '!x[$0]++' | crontab -
# 	job_number=$(cat current_job)
# 	printf "%s\n" "Added job ${job_number} to crontab"
# }

check_input_files() { # See if INCAR, KPOINTS, POSCAR, and runVASP.sh exist. If they do, return 0 (success, similar to grep). If one or more are not found, return 1.
	INCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "INCAR")
	KPOINTS_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "KPOINTS")
	POSCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "POSCAR")
	runVASP_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "runVASP.sh")

	if [[ -n "${INCAR_file}" ]] && [[ -n "${KPOINTS_file}" ]] && [[ -n "${POSCAR_file}" ]] && [[ -n "${runVASP_file}" ]] ; then
		echo "0"
	else
		echo "1"
	fi
}

conditional_run() { # If running, do nothing. If done, check for an error or see if it got stuck. If no current_job file found, check if slurm file found. If slurm found, check if error or got stuck. If no slurm found, check for input files. If input files found, submit calculation. If no input files found, check folders (if "slurm" or "run" not in folder title)
	check_if_running
	printf "Checking job status ... " >&3
	if [[ "${job_status}" == 0 ]] ; then
		printf "%s\n" "Job ${job_number} is already running" >&3
		# save_nodes
	elif [[ "${job_status}" == 1 ]] ; then
		printf "job is inactive\n" >&3
		update_and_run_if_error
	elif [[ "${job_status}" == 2 ]] ; then
		printf "could not check status, no job number found\n" >&3
		printf "Checking for slurm file ... " >&3
		if [[ -n "${slurm_file}" ]] ; then
			printf "%s\n" "found slurm" >&3
			update_and_run_if_error
		else
			printf "%s\n" "no slurm found" >&3
			printf "Checking for input files ... " >&3
			if [[ $(check_input_files) == 0 ]] ; then
				printf "%s\n" "found input files" >&3
				printf "%s\n" "Running new job in $(pwd)"
				run_and_catch_job
				add_to_crontab
			else
				printf "%s\n" "no input files found" >&3
				run_in_folders
			fi
		fi
	fi
}

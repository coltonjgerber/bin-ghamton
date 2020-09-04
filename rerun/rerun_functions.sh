#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

# TODO:
# Have continueVASP work with run folders 2 digits or more?
# Automate runVASP naming, maybe using folder name at end (prep base name)
# Automate removing entries from POSCAR easier

source verbose_mode.sh # adds option for verbose mode using -v or other option
is_aimd=false
suppress_individual_emails=false
crontab_options=
if [[ -n "${1+x}" ]] ; then
	while :; do
		case ${1-default} in
			(-a|--auto)
				suppress_individual_emails=true
				crontab_options="${crontab_options}--auto "
				;;
			(--AIMD)
				is_aimd=true
				crontab_options="${crontab_options}--AIMD "
				;;
			(--) # End of all options.
				shift
				break
				;;
			(*) # Default case: No more options, so break out of the loop.
				break
		esac
		shift
	done
fi

# Submit job and catch output to grab job number, then send output to stdout
# run_and_catch_job() {
# 	if [[ -e ./POTCAR ]] ; then rm POTCAR ; fi
# 	potcar.sh
# 	sed -i 's/.*--exclude.*/'"$(cat ~/bin/exclude_list)"'/' runVASP.sh
# 	sbatch_output=$(sbatch runVASP.sh)
# 	printf "%s\n" "${sbatch_output}"
# 	printf "%s" "${sbatch_output#'Submitted batch job '}" > current_job
# }

# WARNING: if you cancel a calculation, IMMEDIATELY use crontab -e to edit your crontab file and remove the line corresponding to the calculation you cancelled. Otherwise, crontab will keep trying to execute the script and will either restart the calculation or (more likely) fill up your mailbox with error messages.
# Adds a line to crontab to excute rerunVASP (check if running or stopped) every minute. 
add_to_crontab() {
	if [[ "$(pwd)" == *"NEB"* ]] && [[ "$(pwd)" == *"actual"* ]] ; then
		(crontab -l ; echo "*/5 * * * * cd $(pwd) && rerunNEB.sh") | awk '!x[$0]++' | crontab -
	else 
		(crontab -l ; echo "* * * * * cd $(pwd) && rerunVASP.sh ${crontab_options}") | awk '!x[$0]++' | crontab -
	fi
	job_number=$(cat current_job)
	printf "%s\n" "Added job ${job_number} to crontab"
}

# Remove the added line from crontab
remove_from_crontab() {
	crontab -l | grep -v "$(pwd)" | crontab -
	printf "%s\n" "Removed job ${job_number} from crontab"
}

check_folders_finished() {
	# printf "Checking for folder list ... " 
	# if [[ -n "${folder_list}" ]] ; then
		# printf "found folder list\n"
		# __finished_var=$1
		check_result=0
		while IFS="" read -r folder || [ -n "${folder}" ] ; do
			folder_name=$(basename "${folder}")
			printf "%s" "Checking name of folder ${folder_name} ... " >&3
			if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
				printf "OK\n" >&3
				cd "${folder}"
				find_slurm_and_job
				printf "%s" "Checking for completion in folder ${folder_name} ... " >&3
				if [[ $(grep -q 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}" 2>/dev/null; echo $?) == 0 ]] ; then
					printf "OK\n" >&3
				else
					printf "incomplete\n" >&3
					check_result=1
					# eval $__finished_var="'${check_result}'"
					return 1
				fi
				cd ../
			else
				printf "skipping folder\n" >&3
			fi
		done < <(printf '%s\n' "${folder_list}")
		# eval $__finished_var="'${check_result}'"
		return 0
	# fi
}

# Below function is unfinished, but was working at one point in time. 
mail_if_folders_finished() {
result=
check_folders_finished result
printf "Checking folder results ... " >&3
if [[ "${result}" == 0 ]] ; then
	printf "OK \n"
	# mailx -s "${job_name#'#SBATCH -J '} removed from crontab" "${USER}@binghamton.edu" <<-EOF
	# 	Completed: $(pwd)
	# 	EOF
	printf "Would send mail, 10/10\n"
else
	printf "not all folders finished" >&3
fi
}

add_folder_crontab() {
	if [[ "$(pwd)" == *"NEB"* ]] && [[ "$(pwd)" == *"actual"* ]] ; then
		(crontab -l ; echo "*/5 * * * * cd $(pwd) && rerunVASP.sh") | awk '!x[$0]++' | crontab -
	else 
		(crontab -l ; echo "* * * * * cd $(pwd) && rerunVASP.sh") | awk '!x[$0]++' | crontab -
	fi
	job_number=$(cat current_job)
	printf "%s\n" "Added job ${job_number} to crontab"
}

# Checks slurm for node-failing errors (does not include SEGFAULT currently). If error found, update exclude_list. If no error found, check if got stuck or ran out of steps. If neither of those, remove line from crontab file
update_and_run_if_error() {
	printf 'Checking slurm for errors ... ' >&3
	grep "rc_verbs_iface.c:[0-9][0-9]   send completion with error: remote invalid request error" "${slurm_file}" > error_list 2> /dev/null || :	# find lines with error code

	if [[ -s error_list ]] ; then # Check if node-failing errors in slurm
		printf "found errors\n" >&3
		source update_exclude_list.sh 1>&3 # make functions inupdate_exclude_list available for use
		run_and_catch_job 1>&3
		add_to_crontab 1>&3
	else 
		printf "no errors found\n" >&3
		source continueVASP.sh
		printf "Checking if ran out of steps or got stuck ... "
		if [[ -n "${max_step_line}" ]] ; then # Check if ran out of steps. Gets steps from NSW in INCAR
			printf "ran out of steps\n"
			move_and_clean_up_files
			# if [[ -n $(find . -maxdepth 1 -mindepth 1 -type d -name "5run*") ]] ; then
			# 	return # Exit function if already completed 5 runs
			# fi
			printf "%s\n" "Continuing job that ran out of steps in $(pwd)"
			run_and_catch_job
			add_to_crontab
		elif [[ -n "${stuck_line}" ]] ; then # Check if error from getting stuck in local minimum is in slurm
			printf "got stuck\n"
			move_and_clean_up_files
			# if [[ -n $(find . -maxdepth 1 -mindepth 1 -type d -name "5run*") ]] ; then
			# 	return
			# fi
			printf "%s\n" "Continuing job that got stuck in $(pwd)"
			run_and_catch_job
			add_to_crontab
		elif [[ -n "${timeout_line}" ]] ; then
			printf "timed out\n"
			move_and_clean_up_files
			printf "%s\n" "Continuing job that timed out in $(pwd)"
			run_and_catch_job
			add_to_crontab
		else # Remove line from crontab file
			printf "did not run out of steps or get stuck\n"
			printf "%s\n" "Job assumed completed in $(pwd)" 
			job_name=$(grep '#SBATCH -J' runVASP.sh)
			if ! "${suppress_individual_emails}" ; then
				mailx -s "${job_name#'#SBATCH -J '} removed from crontab" "${USER}@binghamton.edu" <<-EOF
					Completed: $(pwd)
					EOF
			fi
			remove_from_crontab

		fi
	fi
}

check_if_running() { # Use current_job to check if running. 
	printf "Checking for job number ... " >&3
	if [[ -n "${current_job_file}" ]] ; then
		printf "found job number\n" >&3
		job_number=$(cat current_job)
		job_status=$(squeue -u "${USER}" | grep -q "${job_number}" 2> /dev/null; echo $?)
	else
		printf "no job number found\n" >&3
		job_status="2"
	fi
}

save_nodes() { 
	squeue -u "${USER}" | grep "${job_number}" 2> /dev/null | grep -Po '(?<=compute|compute\[)[0-9]{3,}(-[0-9]{3,}(?=\]))?' > nodes_used
	if [[ "$(cat nodes_used)" == *"-"* ]] ; then
		perl -pe 's/(\d+)-(\d+)/join("\n", $1..$2)/ge' nodes_used
	fi
	# squeue -u "${USER}" | grep "${job_number}" 2> /dev/null | grep -Eo 'compute\[?[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used 2> /dev/null || :
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -o 'compute[\?[0-9]\{3,\}\(-[0-9]\{3,\}]\)\?' > nodes_used
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Eo '(compute)\[?[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Po '(?<=compute)\[?[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used # works for no bracket
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Po '(?<=compute|compute\[)[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used  # works but keeps final bracket
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Po '(?<=compute|compute\[)[0-9]{3,}(-[0-9]{3,}(?=\]))?' > nodes_used
}

# check_input_files() { # See if INCAR, KPOINTS, POSCAR, and runVASP.sh exist. If they do, return 0 (success, similar to grep). If one or more are not found, return 1.
# 	INCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "INCAR")
# 	KPOINTS_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "KPOINTS")
# 	POSCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "POSCAR")
# 	runVASP_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "runVASP.sh")

# 	if [[ -n "${INCAR_file}" ]] && [[ -n "${KPOINTS_file}" ]] && [[ -n "${POSCAR_file}" ]] && [[ -n "${runVASP_file}" ]] ; then
# 		echo "0"
# 	else
# 		echo "1"
# 	fi
# }

# conditional_run() { # If running, do nothing. If done, check for an error or see if it got stuck. If no current_job file found, check if slurm file found. If slurm found, check if error or got stuck. If no slurm found, check for input files. If input files found, submit calculation. If no input files found, check folders (if "slurm" or "run" not in folder title)
# 	check_if_running
# 	printf "Checking job status ... " >&3
# 	if [[ "${job_status}" == 0 ]] ; then
# 		printf "%s\n" "Job ${job_number} is already running" >&3
# 	elif [[ "${job_status}" == 1 ]] ; then
# 		printf "job is inactive\n" >&3
# 		update_and_run_if_error
# 	elif [[ "${job_status}" == 2 ]] ; then
# 		printf "could not check status, no job number found\n" >&3
# 		printf "Checking for slurm file ... " >&3
# 		if [[ -n "${slurm_file}" ]] ; then
# 			printf "%s\n" "found slurm" >&3
# 			update_and_run_if_error
# 		else
# 			printf "%s\n" "no slurm found" >&3
# 			printf "Checking for input files ... " >&3
# 			if [[ $(check_input_files) == 0 ]] ; then
# 				printf "%s\n" "found input files" >&3
# 				printf "%s\n" "Running new job in $(pwd)"
# 				run_and_catch_job
# 				add_to_crontab
# 			else
# 				printf "%s\n" "no input files found" >&3
# 				run_in_folders
# 			fi
# 		fi
# 	fi
# }

find_slurm_and_job() { # Assign variables for checking if slurm and current_job files exist

	slurm_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "slurm*")	#find slurm file
	current_job_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "current_job")
}

find_folder_list() {
	folder_list=$(find . -maxdepth 1 -mindepth 1 -type d -not \( -name "*slurm*" -o -name "*run*" -o -name "*DOS*" -o -name "*bader*" \))
}

run_in_folders() { # Loop through folders, executing find_slurm_and_job and conditional_run in each folder without "slurm" or "run" in the name. No limit to depth of folders checked, but will not check in folders without slurm or run in name.

	printf "%s\n" "No slurm file found in $(basename "$(pwd)")" >&3
	if [[ -n "${folder_list}" ]] ; then
		printf "Checking folders...\n" >&3
		while IFS="" read -r folder || [ -n "${folder}" ] ; do
			if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
				cd "${folder}"
				find_slurm_and_job
				#if [[ -n "${slurm_file}" ]] ; then conditional_run ; else printf "No slurm file found in $(basename ${folder})\n" ; fi
				conditional_run
				cd ../
			else
				printf "%s\n" "Skipping folder $(basename "${folder}")" >&3
			fi
		done < <(printf '%s\n' "${folder_list}")
	else
		printf "No slurm file or folders found" >&3
	fi
}


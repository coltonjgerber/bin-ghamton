#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

# TODO:
# Have continueVASP work with run folders 2 digits or more?
# Automate runVASP naming, maybe using folder name at end (prep base name)

source verbose_mode.sh # adds option for verbose mode using -v or other option
continue_aimd=false
is_aimd=false
is_auto=false
is_adding_electron=false
suppress_individual_emails=false
crontab_options=
if [[ -z "${is_neb+x}" ]]; then
	is_neb=false
fi
if [[ -n "${1+x}" ]]; then
	while :; do
		case ${1-default} in
		-a | --auto)
			is_auto=true
			suppress_individual_emails=true
			crontab_options="${crontab_options}--auto "
			;;
		--AIMD)
			is_aimd=true
			crontab_options="${crontab_options}--AIMD "
			;;
		-c | --continue)
			continue_aimd=true
			crontab_options="${crontab_options}-c "
			;;
		-e) # For adding an electron when continuing an AIMD run; must also use --AIMD
			is_adding_electron=true
			crontab_options="${crontab_options}-e "
			;;
		--) # End of all options.
			shift
			break
			;;
		*) # Default case: No more options, so break out of the loop.
			break ;;
		esac
		shift
	done
fi

# Submit job and catch output to grab job number, then send output to stdout
run_and_catch_job() {
	if ! "${is_neb}"; then
		if [[ -e ./POTCAR ]]; then rm POTCAR; fi
		potcar.sh
	fi
	sed -i 's/.*--exclude.*/'"$(cat ~/bin/exclude_list)"'/' runVASP.sh
	sbatch_output=$(sbatch runVASP.sh)
	printf "%s\n" "${sbatch_output}"
	printf "%s" "${sbatch_output#'Submitted batch job '}" >current_job
}

# WARNING: if you cancel a calculation, IMMEDIATELY use crontab -e to edit your crontab file and remove the line
# corresponding to the calculation you cancelled. Otherwise, crontab will keep trying to execute the script and will
# either restart the calculation or (more likely) fill up your mailbox with error messages.
# Adds a line to crontab to execute rerunVASP (check if running or stopped) every minute.
add_to_crontab() {
	if "${is_neb}"; then
		(
			crontab -l
			echo "*/5 * * * * cd $(pwd) && rerunNEB.sh"
		) | awk '!x[$0]++' | crontab -
	else
		(
			crontab -l
			echo "* * * * * cd $(pwd) && rerunVASP.sh ${crontab_options}"
		) | awk '!x[$0]++' | crontab -
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
	while IFS="" read -r folder || [ -n "${folder}" ]; do
		folder_name=$(basename "${folder}")
		printf "%s" "Checking name of folder ${folder_name} ... " >&3
		if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]]; then
			printf "OK\n" >&3
			cd "${folder}"
			find_slurm_and_job
			printf "%s" "Checking for completion in folder ${folder_name} ... " >&3
			if [[ $(
				grep -q 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}" \
					2>/dev/null
				echo $?
			) == 0 ]]; then
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
	if [[ "${result}" == 0 ]]; then
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
	if "${is_neb}"; then
		(
			crontab -l
			echo "*/5 * * * * cd $(pwd) && rerunVASP.sh"
		) | awk '!x[$0]++' | crontab -
	else
		(
			crontab -l
			echo "* * * * * cd $(pwd) && rerunVASP.sh"
		) | awk '!x[$0]++' | crontab -
	fi
	job_number=$(cat current_job)
	printf "%s\n" "Added job ${job_number} to crontab"
}

# Checks slurm for node-failing errors (does not include SEGFAULT currently). If error found, update exclude_list.
# If no error found, check if got stuck or ran out of steps. If neither of those, remove line from crontab file
update_and_run_if_error() {
	printf 'Checking slurm for errors ... ' >&3
	grep "rc_verbs_iface.c:[0-9][0-9]   send completion with error: remote invalid request error" \
		"${slurm_file}" >error_list 2>/dev/null || : # find lines with error code

	if [[ -s error_list ]]; then # Check if node-failing errors in slurm
		printf "found errors\n" >&3
		source update_exclude_list.sh 1>&3 # make functions inupdate_exclude_list available for use
		run_and_catch_job 1>&3
		add_to_crontab 1>&3
	else
		printf "no errors found\n" >&3
		check_if_ran_out
		check_if_got_stuck
		check_if_timeout
		printf "Checking if ran out of steps or got stuck ... "
		if { [[ -n "${max_step_line}" ]] && ! { "${is_aimd}" && ! "${continue_aimd}"; }; } ||
			[[ -n "${stuck_line}" ]] || [[ -n "${timeout_line}" ]] ; then
			printf "%s\n" "${calculation_result}"
			move_and_clean_up_files
			printf "%s\n" "Continuing job that ${calculation_result} in $(pwd)"
			run_and_catch_job
			add_to_crontab
		else # Remove line from crontab file
			printf "did not run out of steps, get stuck, or time out\n"
			printf "%s\n" "Job assumed completed in $(pwd)"
			job_name=$(grep '#SBATCH -J' runVASP.sh)
			if ! "${suppress_individual_emails}"; then
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
	if [[ -n "${current_job_file}" ]]; then
		printf "found job number\n" >&3
		job_number=$(cat current_job)
		job_status=$(
			squeue -u "${USER}" | grep -q "${job_number}" 2>/dev/null
			echo $?
		)
	else
		printf "no job number found\n" >&3
		job_status="2"
	fi
}

save_nodes() {
	squeue -u "${USER}" | grep "${job_number}" 2>/dev/null |
		grep -Po '(?<=compute|compute\[)[0-9]{3,}(-[0-9]{3,}(?=\]))?' >nodes_used
	if [[ "$(cat nodes_used)" == *"-"* ]]; then
		perl -pe 's/(\d+)-(\d+)/join("\n", $1..$2)/ge' nodes_used
	fi
	# Below was used for testing save_nodes (not yet implemented)
	# squeue -u "${USER}" | grep "${job_number}" 2> /dev/null | grep -Eo 'compute\[?[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used 2> /dev/null || :
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -o 'compute[\?[0-9]\{3,\}\(-[0-9]\{3,\}]\)\?' > nodes_used
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Eo '(compute)\[?[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Po '(?<=compute)\[?[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used # works for no bracket
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Po '(?<=compute|compute\[)[0-9]{3,}(-[0-9]{3,}\])?' > nodes_used  # works but keeps final bracket
	# squeue -u "${USER}" | grep "$(cat current_job)" 2> /dev/null | grep -Po '(?<=compute|compute\[)[0-9]{3,}(-[0-9]{3,}(?=\]))?' > nodes_used
}

# See if INCAR, KPOINTS, POSCAR, and runVASP.sh exist. If they do, return 0 (success, similar to grep). If one or more
# are not found, return 1.
check_input_files() {
	INCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "INCAR")
	KPOINTS_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "KPOINTS")
	runVASP_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "runVASP.sh")
	if "${is_neb}"; then
		if [[ -n "${INCAR_file}" ]] && [[ -n "${KPOINTS_file}" ]] && [[ -n "${runVASP_file}" ]]; then
			echo "0"
		else
			echo "1"
		fi
	else
		POSCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "POSCAR")
		if [[ -n "${INCAR_file}" ]] && [[ -n "${KPOINTS_file}" ]] && [[ -n "${POSCAR_file}" ]] &&
			[[ -n "${runVASP_file}" ]]; then
			echo "0"
		else
			echo "1"
		fi
	fi
}

# Assign variables for checking if slurm and current_job files exist
find_slurm_and_job() {

	slurm_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "slurm*") #find slurm file
	current_job_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "current_job")
}

# Find folders in current directory (without slurm, run, or DOS in folder name) and list as lines in variable
# folder_list
find_folder_list() {
	folder_list=$(find . -maxdepth 1 -mindepth 1 -type d -not \( -name "*slurm*" -o -name "*run*" -o -name "*DOS*" -o \
		-name "*bader*" \))
}

# Loop through folders, executing find_slurm_and_job and conditional_run in each folder without "slurm" or "run" in the
# name. No limit to depth of folders checked, but will not check in folders without slurm or run in name.
run_in_folders() {

	printf "%s\n" "No slurm file found in $(basename "$(pwd)")" >&3
	if [[ -n "${folder_list}" ]]; then
		printf "Checking folders...\n" >&3
		while IFS="" read -r folder || [ -n "${folder}" ]; do
			if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]]; then
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

# Submit job and catch output to grab job number, then send output to stdout
run_and_catch_job() {
	if ! "${is_neb}"; then
		if [[ -e ./POTCAR ]]; then rm POTCAR; fi
		potcar.sh
	fi
	sed -i 's/.*--exclude.*/'"$(cat ~/bin/exclude_list)"'/' runVASP.sh
	sbatch_output=$(sbatch runVASP.sh)
	printf "%s\n" "${sbatch_output}"
	printf "%s" "${sbatch_output#'Submitted batch job '}" >current_job
}

# See if INCAR, KPOINTS, POSCAR, and runVASP.sh exist. If they do, return 0 (success, similar to grep). If one or more
# are not found, return 1.
check_input_files() {
	INCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "INCAR")
	KPOINTS_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "KPOINTS")
	runVASP_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "runVASP.sh")
	if "${is_neb}"; then
		if [[ -n "${INCAR_file}" ]] && [[ -n "${KPOINTS_file}" ]] && [[ -n "${runVASP_file}" ]]; then
			echo "0"
		else
			echo "1"
		fi
	else
		POSCAR_file=$(find . -maxdepth 1 -mindepth 1 -type f -name "POSCAR")
		if [[ -n "${INCAR_file}" ]] && [[ -n "${KPOINTS_file}" ]] && [[ -n "${POSCAR_file}" ]] && [[ -n "${runVASP_file}" ]]; then
			echo "0"
		else
			echo "1"
		fi
	fi
}

# If running, do nothing. If done, check for an error or see if it got stuck. If no current_job file found, check if
# slurm file found. If slurm found, check if error or got stuck. If no slurm found, check for input files. If input
# files found, submit calculation. If no input files found, check folders (if "slurm" or "run" not in folder title)
conditional_run() {
	check_if_running
	printf "Checking job status ... " >&3
	if [[ "${job_status}" == 0 ]]; then
		printf "%s\n" "Job ${job_number} is already running" >&3
		# save_nodes (function to record which nodes a calculation ran on; INCOMPLETE)
	elif [[ "${job_status}" == 1 ]]; then
		printf "job is inactive\n" >&3
		update_and_run_if_error
	elif [[ "${job_status}" == 2 ]]; then
		printf "could not check status, no job number found\n" >&3
		printf "Checking for slurm file ... " >&3
		if [[ -n "${slurm_file}" ]]; then
			printf "%s\n" "found slurm" >&3
			update_and_run_if_error
		else
			printf "%s\n" "no slurm found" >&3
			printf "Checking for input files ... " >&3
			if [[ $(check_input_files) == 0 ]]; then
				printf "%s\n" "found input files" >&3
				printf "%s\n" "Running new job in $(pwd)"
				run_and_catch_job
				add_to_crontab
			else
				printf "%s\n" "no input files found" >&3
				if ! "${is_neb}"; then
					run_in_folders
				fi
			fi
		fi
	fi
}
################################################## CONTINUEVASP FUNCTIONS ARE BELOW ####################################
# Search slurm output for line with step value equal to NSW in INCAR
check_if_ran_out() {
	ionic_steps=$(grep 'NSW' INCAR)
	ionic_steps="${ionic_steps#'NSW = '}"
	if ! [[ $(
		grep -q 'reached required accuracy - stopping structural energy minimisation' "${slurm_file}" \
			2>/dev/null
		echo $?
	) == 0 ]]; then
		max_step_line=$(grep "${ionic_steps} F=" "${slurm_file}" 2>/dev/null || :)
		if [[ -n "${max_step_line}" ]]; then
			if "${is_aimd}"; then
				calculation_result="finished AIMD trajectory"
			else
				calculation_result="ran out of steps"
			fi
		fi
	else
		max_step_line=""
	fi
}

# Check slurm for error indicating it got stuck in a local minimum
check_if_got_stuck() {
	stuck_line=$(grep 'ZBRENT: fatal error in bracketing
		 please rerun with smaller EDIFF, or copy CONTCAR' "${slurm_file}" 2>/dev/null ||
		grep 'ZBRENT: fatal error: bracketing interval incorrect
     please rerun with smaller EDIFF, or copy CONTCAR' "${slurm_file}" 2>/dev/null || :)
	if [[ -n "${stuck_line}" ]]; then
		calculation_result="got stuck"
	fi
}

check_if_timeout() {
	timeout_line=$(grep 'DUE TO TIME LIMIT' "${slurm_file}" 2>/dev/null || :)
	if [[ -n "${timeout_line}" ]]; then
		calculation_result="timed out"
	fi
}

copy_all_except_previous_runs() {
	shopt -s extglob
	eval 'cp -r !(+([0-9])run*|failed_slurms) "${1}"'
}

# Starting with 1run, check if folder exists. If not, make folder and copy all files (and folders, if they exist) except
# failed_slurms to 1run folder. If it exists, check if 2run exists. If not, create (i)run folder and copy all files from
# previous run. If it's NEB, keep making irun folders until you get to 40. If it's not NEB, stop if 1run-5run folders
# already exist
save_run_in_directory() {
	printf "Creating directory ... " >&3
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40; do
		# If 5run already exists, send an email and exit
		if ! "${is_neb}" && ! "${is_aimd}"; then
			if [[ "${i}" == 6 ]]; then
				printf "%s\n" "6 runs completed, no more runs will be attempted for job in $(pwd)"
				job_name=$(grep '#SBATCH -J' runVASP.sh)
				mailx -s "${job_name#'#SBATCH -J '} removed from crontab" "${USER}@binghamton.edu" <<-EOF
					5 (or probably 6) runs without converging: $(pwd)
				EOF
				printf "Sent email"
				exit
			fi
		fi
		# If (i)run folder not found, create folder, copy all files from previous run, and exit for loop
		if [[ -z $(find . -maxdepth 1 -mindepth 1 -type d -name "*${i}run*") ]]; then
			mkdir "${i}run"
			printf "%s\n" "created directory ${i}run" >&3
			printf "Copying all files and folders except previous runs ... " >&3
			copy_all_except_previous_runs "${i}run"
			printf "done\n" >&3
			break
		fi
		printf "%s" "${i}run already exists ... " >&3 # If run does not already exist, the loop should break before this
		# command in the previous if statement
	done
}

move_and_clean_up_files() {
	remove_from_crontab
	save_run_in_directory
	# save_run in directory should already have copied the slurm file into the Nrun folder. The below is a backup that
	# also removes it from the folder in which the calculation will be run
	if [[ -n "${slurm_file}" ]]; then
		mv "${slurm_file}" "${i}run"
	fi
	if [[ -n "${current_job_file}" ]]; then
		rm "${current_job_file}"
	fi
	# Comment the below line in if you want to clear the failed_slurms folder after continuing a calculation.
	#find . -maxdepth 1 -mindepth 1 -name "failed_slurms" -type d -exec rm -rf {} +

	# Cycle through folders, moving CONTCAR to POSCAR if CONTCAR exists.
	if ! "${is_neb}"; then
		if "${is_auto}"; then
			source read_ions_from_POSCAR.sh # If ions are not labeled in original POSCAR, this will break the script
			cp CONTCAR CONTCAR.bk
			if ! "${is_empty}"; then
				label_ions.sh 8 "${ion_element}" CONTCAR
			fi
		fi
		mv CONTCAR POSCAR
		if "${is_adding_electron}"; then
			add_electron
		fi
	else
		while IFS="" read -r folder || [ -n "${folder}" ]; do
			folder_name="$(basename "${folder}")"
			printf "%s" "Checking folder ${folder_name} ... " >&3
			if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]]; then
				cd "${folder}"
				if [[ -e CONTCAR ]]; then
					mv CONTCAR POSCAR
					printf "moved CONTCAR to POSCAR\n" >&3
				else
					printf "no CONTCAR\n" >&3
				fi
				cd ../
			else
				printf "skipped folder" >&3
			fi
		done < <(printf '%s\n' "${folder_list}")
	fi
}

add_electron() {
	nelect_value="$(grep 'NELECT' INCAR)"
	nelect_value="${nelect_value#'NELECT[space]*=[space]*'}"
	echo "${nelect_value}"
	nelect_value=$((nelect_value + 1))
	sed -i "s/NELECT =.*$/NELECT = ${nelect_value}/" INCAR
}

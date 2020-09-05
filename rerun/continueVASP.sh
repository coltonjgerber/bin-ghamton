#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

check_if_ran_out() {
	# check number of ionic steps (NSW) in INCAR
	ionic_steps=$(grep 'NSW' INCAR)
	ionic_steps="${ionic_steps#'NSW = '}"
	# search slurm for line with step value equal to NSW
#	if "${is_aimd}" ; then
#		max_step_line=""
#	else
		max_step_line=$(grep "${ionic_steps} F=" "${slurm_file}" 2> /dev/null || :)
#	fi
	}

check_if_got_stuck() { # check slurm for error indicating it got stuck in a local minimum
	stuck_line=$(grep 'ZBRENT: fatal error in bracketing
		 please rerun with smaller EDIFF, or copy CONTCAR' "${slurm_file}" 2> /dev/null || grep 'ZBRENT: fatal error: bracketing interval incorrect
     please rerun with smaller EDIFF, or copy CONTCAR' "${slurm_file}" 2> /dev/null || :)

}

check_if_timeout() {
	timeout_line=$(grep 'DUE TO TIME LIMIT' "${slurm_file}" 2> /dev/null || :)
}

check_if_NEB() {
	# Wildcards in below conditional must be outside quotes. The conditional appears to use regex, not globbing
	if { [[ "$(pwd)" == *"NEB"* ]] && [[ "$(pwd)" == *"actual"* ]]; } ; then
		is_neb=true
	else
		is_neb=false
	fi
}

copy_all_except_previous_runs() {
	shopt -s extglob
	eval 'cp -r !(+([0-9])run*|failed_slurms) "${1}"'
}

# Starting with 1run, check if folder exists. If not, make folder and copy all files (and folders, if they exist) except failed_slurms to 1run folder. If it exists, check if 2run exists. If not...
# For non-NEB calculations, exits if 1run-5run already exist
save_run_in_directory() {
	printf "Creating directory ... " >&3
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40; do
		# If 5run already exists, send an email and exit
		if ! "${is_neb}" && ! "${is_aimd}"; then
			if [[ "${i}" == 6 ]] ; then 
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
		if [[ -z $(find . -maxdepth 1 -mindepth 1 -type d -name "*${i}run*") ]] ; then
			mkdir "${i}run"
			printf "%s\n" "created directory ${i}run" >&3
			printf "Copying all files and folders except previous runs ... " >&3
			copy_all_except_previous_runs "${i}run"
			printf "done\n" >&3
			break
		fi
		printf "%s" "${i}run already exists ... " >&3 # If run does not already exist, the loop should break before this command in the previous if statement
	done
}


move_and_clean_up_files() {
	remove_from_crontab
	save_run_in_directory
	# if [[ -n $(find . -maxdepth 1 -mindepth 1 -type d -name "5run*") ]] ; then
	# 	return
	# fi
	# save_run in directory should already have copied the slurm file into the Nrun folder. The below is a backup that also removes it from the folder in which the calculation will be run
	if [[ -n "${slurm_file}" ]] ; then
		mv "${slurm_file}" "${i}run"
	fi
	if [[ -n "${current_job_file}" ]] ; then
		rm "${current_job_file}"
	fi
	#It seemed better to not copy the failed_slurms folder when all other files and folders are copied, so as to avoid having many failed_slurms folders. However, removing it also seems risky, as you may want the failed slurms as a record. Comment the below line in if you want to clear the failed_slurms folder after continuing a calculation.
	#find . -maxdepth 1 -mindepth 1 -name "failed_slurms" -type d -exec rm -rf {} +

	# If path does not contain "NEB" and "actual", move CONTCAR to POSCAR. Otherwise, cycle through folders, moving CONTCAR to POSCAR if CONTCAR exists. You must use a folder with "actual" in the name to run your NEB calculations (the real NEB calculations, not the relaxations to get the start and end points; this is set up to still allow you to use rerunVASP for the relaxation part of NEB)
	if ! "${is_neb}" ; then
		if "${is_auto}" ; then
			source read_ions_from_POSCAR.sh # This has the potential to cause problems. If ions are not labeled in original POSCAR, the script will break.
			cp CONTCAR CONTCAR.bk
			if ! "${is_empty}" ; then
				label_ions.sh 8 "${ion_element}" CONTCAR
			fi
		fi
		mv CONTCAR POSCAR
		if "${is_adding_electron}" ; then
			add_electron
		fi
	else
		while IFS="" read -r folder || [ -n "${folder}" ] ; do
			folder_name="$(basename "${folder}")"
			printf "%s" "Checking folder ${folder_name} ... " >&3
			if [[ ! "${folder}" == *slurm* ]] && [[ ! "${folder}" == *run* ]] ; then
				cd "${folder}"
				if [[ -e CONTCAR ]] ; then
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
	nelect_value="$(grep 'NELECT' INCAR)"; nelect_value="${nelect_value#'NELECT[space]*=[space]*'}"; echo "${nelect_value}"
	nelect_value=$(( nelect_value + 1 ))
	sed -i "s/NELECT =.*$/NELECT = ${nelect_value}/" INCAR
}

check_if_ran_out
check_if_got_stuck
check_if_timeout
check_if_NEB
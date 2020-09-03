#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

slurm_folder_check() {	# check for failed_slurms folder and create if needed

	if [[ -z $(find . -maxdepth 1 -mindepth 1 -name 'failed_slurms') ]] ; then
		mkdir failed_slurms
		printf "Made failed_slurms folder\n" >&3
	else
		printf "Found folder\n" >&3
	fi
}

# substitute each error line with the node number in each line, and write node numbers to error_node_list variable. Also checks for duplicates in current list of errors (will not prevent same node getting added from different jobs)
parse_error_nodes() {	
	error_node_list=$(sed -n 's/.*compute\([0-9][0-9][0-9]\).*/\1/p' error_list | sed '$!N; /^\(.*\)\n\1$/!P; D')
	#printf "Adding node(s)  to exclude list..."
	#printf "Adding node(s) $(jq -Rs . <error_node_list) to exclude list..."
}

# Gets current list of notes in exclude_list file and adds them to an array
get_current_exclude_list() {
	#reading in exclude line from runVASP.sh
	excludeString=$(cat ~/bin/exclude_list)	# get current exclude_list
	excludeString=${excludeString#'#SBATCH --exclude=compute['}	# remove front text
	excludeString=${excludeString%]}	# remove back bracket, leaving numbers or ranges with commas
	IFS=',' read -r -a nodeArray <<< "${excludeString}" # split string using commas and add each node (or range of nodes) to an array
}

# Writes nodes from error_node_list to the array created in get_current_exclude_list, then writes the array to a string with each node (or range) separated by a comma, adds on the #SBATCH text and brackets, and replaces the exclude line in runVASP.sh with the new string
rebuild_exclude_list() {

	#add nodes from error_node_list to end of nodeArray
	while IFS= read -r line || [ -n "${line}" ]
	do
		nodeArray+=("${line}")
	done < <(printf '%s\n' "${error_node_list}")

	IFS=',';new_exclude_line="#SBATCH --exclude=compute[${nodeArray[*]// /|}]"	#convert array to string delimited with "," and add surrounding text
	sed -i 's/.*--exclude.*/'"${new_exclude_line}"'/' ~/bin/exclude_list
	sed -i 's/.*--exclude.*/'"${new_exclude_line}"'/' runVASP.sh	#replace exclude line in runVASP.sh with new_exclude_line
	printf "%s\n" "Updated list of excluded nodes in $(pwd)"
}
#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

# TODO: Handle errors from NEB such as [compute092:7482 :0:7482] rc_verbs_iface.c:67   send completion with error: remote invalid request error

# WARNING: Will not work if exclude_list file is not in a $PATH folder (e.g. ~/bin, if you made that folder) or if runVASP.sh file lacks "#SBATCH --exclude" line. I recommend keeping some exclusion, either 000-032 or 000-041 in all runVASP.sh files. 

# Exclude lines in runVASP.sh files will be replaced with the "master" from exclude_list

source update_exclude_list_functions.sh
slurm_folder_check	# check for failed_slurms failed folder, create it if not found

# move slurm file into folder
cp "${slurm_file}" failed_slurms
rm "${slurm_file}"

parse_error_nodes
get_current_exclude_list
rebuild_exclude_list
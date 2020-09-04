#!/bin/bash

# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
set -o nounset

# End Boilerplate

is_neb=true
suppress_individual_emails=false
suppress_emails_option=

source rerun_functions.sh # make functions (stored in another file) available for use

find_slurm_and_job # finds slurm-xxxxxxxx.out and current_job files, for use in checking if job is running, encountered an error, got stuck or ran out of steps.
find_folder_list
conditional_run # If running, do nothing. If done, check for an error or see if it got stuck. If no current_job file found, check if slurm file found. If slurm found, check if error or got stuck. If no slurm found, check for input files. If input files found, submit calculation. If no input files found, check folders (if "slurm" or "run" not in folder title)

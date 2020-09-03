#!/bin/bash

source rerunVASP_functions.sh
source verbose_mode.sh
folder_list=$(find . -maxdepth 1 -mindepth 1 -type d -not \( -name "*slurm*" -o -name "*run*" \))

printf "Checking for folder list ... " 
if [[ -n "${folder_list}" ]] ; then
	printf "found folder list\n"
	mail_if_folders_finished
fi
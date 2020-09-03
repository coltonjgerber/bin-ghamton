#!/bin/bash

source rerunVASP_functions.sh
source verbose_mode.sh

curr_path=$(pwd)
curr_dir=$(basename "${curr_path}")

if [[ ${1} == '..' ]] ; then
	cd ..
	actual_parent="$(pwd)"
	cd "${curr_dir}"
	if [ ! -d "${actual_parent}"/DOS ] ; then
		mkdir "${actual_parent}"/DOS
	fi
else
	actual_parent="${1}"
	if [ ! -d "${1}"/DOS ] ; then
		mkdir "${1}"/DOS
	fi
fi


mkdir "${actual_parent}"/DOS/initial_run

printf "%s" "Copying files from ${curr_dir} to DOS/initial_run ... " >&3
rsync -q ./* "${actual_parent}"/DOS/initial_run
printf "done\n" >&3

cd "${actual_parent}"/DOS/initial_run
if [[ -e CONTCAR ]] ; then mv CONTCAR POSCAR ; fi
sed -i 's/SIGMA =.*[0-9]/SIGMA = 0.2/' INCAR
printf "Changed SIGMA\n" >&3
sed -i 's/NSW =.*$/NSW = 0/' INCAR
printf "Changed NSW\n" >&3
sed -i 's/#*LORBIT =.*[0-9]/LORBIT = 11/' INCAR
printf "Changed LORBIT\n" >&3
nedos_amt=$(grep 'NEDOS' OUTCAR)
nedos_amt=$(echo "${nedos_amt#"   number of dos      NEDOS =    "}" | sed 's/   number of ions     NIONS.*$//g')
sed -i "/#*LASPH =.*$/a NEDOS = ${nedos_amt}" INCAR
printf "Added NEDOS" >&3

find . -maxdepth 1 -mindepth 1 -type f \( -name "*slurm*" -o -name "current_job" -o -name "error_list" \) -delete
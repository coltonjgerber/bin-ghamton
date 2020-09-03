#!/bin/bash

num_img=$(basename $(dirname $(pwd)))
sed -i "s/\(#SBATCH -J.*\)/\1${num_img}/" runVASP.sh
sed -i "s/IMAGES =.*$/IMAGES = ${num_img}/" INCAR
end_folder="0${num_img}"
nebmake.pl 00/POSCAR "${end_folder}/POSCAR" "${num_img}"
echo "Make sure to set number of cores!"
num_cores=0
while [ $num_cores -le 32 ] ; do
	num_cores=(( "${num_cores}" + "${num_img}" ))
done
sed -i "s/\(#SBATCH -n.*\)/#SBATCH -n ${num_img}/" runVASP.sh

#!/bin/bash

source rerunVASP_functions.sh

is_original=false
is_primitive=false
is_supercell=false
ion_species=
while :; do
	 case ${1-default} in
		(--Ca)
			ion_species="Ca"
			echo "Set Ca"
			;;
		(-o|--orig|--original)
			is_original=true
			echo "Set original"
			;;
		(-p|--prim|--primitive)
			is_primitive=true
			echo "Set primitive"
			;;
		(-s|--super|--supercell)
			is_supercell=true
			echo "Set supercell"
			;;	
		(-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
			;; 
		(--) # End of all options.
			shift
			break
			;;
		(-?*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			;;
		(default) # Default case: No more options, so break out of the loop.
			break
	 esac
	 shift
done

if "${is_primitive}" && [[ "${ion_species}" == "Ca" ]] && "${is_original}"; then
	printf "%s\n" "Copying OUTCARs from /data/home/cgerber/spinel/Ca/primitive_cell/NEB/images/relax"
	initial_outcar="/data/home/cgerber/spinel/Ca/primitive_cell/NEB/images/relax/initial/OUTCAR"
	final_outcar="/data/home/cgerber/spinel/Ca/primitive_cell/NEB/images/relax/final/OUTCAR"
elif "${is_primitive}" && [[ "${ion_species}" == "Ca" ]] && ! "${is_original}"; then
	printf "%s\n" "Copying OUTCARs from /data/home/cgerber/spinel/Ca/primitive_cell/NEB/easier/new_relax/relax"
	initial_outcar="/data/home/cgerber/spinel/Ca/primitive_cell/NEB/easier/new_relax/relax/initial/OUTCAR"
	final_outcar="/data/home/cgerber/spinel/Ca/primitive_cell/NEB/easier/new_relax/relax/final/OUTCAR"
elif "${is_supercell}" && [[ "${ion_species}" == "Ca" ]]; then
	initial_outcar=""
	final_outcar=""
fi


initial_image="00"
final_image="00"
image_list=$(find . -maxdepth 1 -mindepth 1 -type d -name "[0-9][0-9]")
while IFS="" read -r folder || [ -n "${folder}" ] ; do
		folder_name=$(basename "${folder}")
		if (( $(echo "${final_image} < ${folder_name}" | bc -l) )); then
			final_image="${folder_name}"
		fi
done < <(printf '%s\n' "${image_list}")

if ! [[ -f "${initial_image}/OUTCAR" ]] ; then
	cp "${initial_outcar}" "${initial_image}"
	printf "%s\n" "OUTCAR placed in ${initial_image}"
else
	printf "%s\n" "${initial_image}/OUTCAR already exists"
fi
if ! [[ -f "${final_image}/OUTCAR" ]] ; then
	cp "${final_outcar}" "${final_image}"
	printf "%s\n" "OUTCAR placed in ${final_image}"
else
	printf "%s\n" "${final_image}/OUTCAR already exists"
fi



#!/bin/bash

# TODO: Add code to put "Selective Dynamics" before "Direct" line

# PARAMETERS:
# 1 = number of ions
# 2 = file to label (e.g. POSCAR or CONTCAR)

file_to_label="${2}"
tmpfile=$(mktemp)

cp "${file_to_label}" "$tmpfile" && gawk -v numions="${1}" '
	/Direct/ {
		printf "Selective Dynamics\n";
		print;
		for (i = 1; i <= numions; i++) {
			getline;
			printf "%s", $0;
			printf "%s\n", " T T T" ;
		}
		for (i = 1; i <= 4; i++) {
			getline;
			printf "%s", $0;
			printf "%s\n", " F F F" ;
		}

		for (i = 1; i <= 8; i++) {
			getline;
			printf "%s", $0;
			printf "%s\n", " F F F" ;
		}
	next}1' "$tmpfile" >"${file_to_label}"

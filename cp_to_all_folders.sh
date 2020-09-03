#!/bin/bash

if [ -v "${2}" ] ; then
	printf "%s\n" "Filtering to folders with ${2} and copying ... "
	find . -maxdepth 1 -mindepth 1 -type d -name "*${2}*" -exec cp "${1}" {} \;
	printf "done\n"
else
	printf "Copying ... "
	#awk -vORS=, '{ print $2 }' file.txt | sed 's/,$/\n/'
	find . -maxdepth 1 -mindepth 1 -type f 
	find . -maxdepth 1 -mindepth 1 -type d -exec cp eval {} \;
	printf "done\n"
fi

#find Documents \( -name "*.py" -a ! -name '.' -a ! -name '..'\)
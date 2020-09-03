#!/bin/bash

# adds option for verbose mode using -v or other option. Many outputs are redirected to &3 to keep them from going to stdout (&1), and this brings them back to stdout. Having verbose mode off allows for crontab mail to not be generated unless a caclulation is resubmitted (because it got stuck or ran out of steps) or rerunVASP encounters an error

verbose=

if [[ -n "${1+x}" ]] ; then
	case "$1" in
		-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
		verbose=1
		shift ;;
	esac
fi

if [ "${verbose}" = 1 ]; then
    exec 4>&2 3>&1
else
    exec 4>/dev/null 3>/dev/null
fi
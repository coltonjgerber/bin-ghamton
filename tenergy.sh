####################################################################################################
# This file was created on: 03/21/2019, edited on: 03/26/2019, 05/16/2019                          #
#                                                                                                  #
# PURPOSE: To find a slurm-NUMBER.out file by NUMBER.                                              #
#          You submit this script, from any directory, with the command 'find.sh' NUMBER PATH,     #
#          where NUMBER is the number of the slurm file you are trying to find and PATH can be     #
#          left blank or some part of the path where you think the slurm file may be located.      #
####################################################################################################

#!/bin/bash
grep "T=" OSZICAR | awk '{print$1"    "$3"    "$5}' > T_E.txt

echo "DONE!"


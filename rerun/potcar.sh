#!/bin/bash

####################################################################################################
# This file was created on: 04/29/2019, edited on: 05/16/2019, 05/23/2019, 09/11/2019              # 
#                                                                                                  #
# PURPOSE: This is an attempt to make the creation of POTCAR files more automated. The location of #
#          your pseudopotentials needs to be specified. The desired individual pseudopotential     #
#          files are obtained and then concatenated into one POTCAR file.                          #
#                                                                                                  #
#          You submit this script, from any directory, with the command 'set_POSCAR.sh'            #
####################################################################################################

# Where the pseudopotentials you want to use are located
location=~/Potentials/PBE.54

# Determing if 'POSCAR' is present
if [ -e ./POSCAR ]; then

  # Determing which elements are present in 'POSCAR'
  printf "Determining which elements are present in POSCAR ... " >&3
  sed -n '6p' POSCAR | tr -s ' ' '\n' > elements.txt; sed -i '/^$/d' elements.txt 
	sed -i 's/\r//' elements.txt; printf "done\n" >&3

  # Set which pseudopotential files you want based on the elements you use.
  printf "Creating POTCAR file ... "
  while IFS= read -r line; do
    case $line in
      Ag) cp $location/Ag/POTCAR $PWD/Ag_POTCAR; cat Ag_POTCAR >> POTCAR ;;
      Al) cp $location/Al/POTCAR $PWD/Al_POTCAR; cat Al_POTCAR >> POTCAR ;;
      Ar) cp $location/Ar/POTCAR $PWD/Ar_POTCAR; cat Ar_POTCAR >> POTCAR ;;
      As) cp $location/As/POTCAR $PWD/As_POTCAR; cat As_POTCAR >> POTCAR ;;
      Au) cp $location/Au/POTCAR $PWD/Au_POTCAR; cat Au_POTCAR >> POTCAR ;;
      Bi) cp $location/Bi/POTCAR $PWD/Bi_POTCAR; cat Bi_POTCAR >> POTCAR ;;
      C)  cp $location/C/POTCAR $PWD/C_POTCAR; cat C_POTCAR >> POTCAR ;;
      Ca) cp $location/Ca_sv/POTCAR $PWD/Ca_POTCAR; cat Ca_POTCAR >> POTCAR ;;
      Cl) cp $location/Cl/POTCAR $PWD/Cl_POTCAR; cat Cl_POTCAR >> POTCAR ;;      
      Co) cp $location/Co/POTCAR $PWD/Co_POTCAR; cat Co_POTCAR >> POTCAR ;;
      Cu) cp $location/Cu/POTCAR $PWD/Cu_POTCAR; cat Cu_POTCAR >> POTCAR ;;
      H)  cp $location/H/POTCAR $PWD/H_POTCAR; cat H_POTCAR >> POTCAR ;;
      He) cp $location/He/POTCAR $PWD/He_POTCAR; cat He_POTCAR >> POTCAR ;;
      Kr) cp $location/Kr/POTCAR $PWD/Kr_POTCAR; cat Kr_POTCAR >> POTCAR ;;
      Li) cp $location/Li/POTCAR $PWD/Li_POTCAR; cat Li_POTCAR >> POTCAR ;;
      Mg) cp $location/Mg/POTCAR $PWD/Mg_POTCAR; cat Mg_POTCAR >> POTCAR ;;
      Mn) cp $location/Mn/POTCAR $PWD/Mn_POTCAR; cat Mn_POTCAR >> POTCAR ;;
      N)  cp $location/N/POTCAR $PWD/N_POTCAR; cat N_POTCAR >> POTCAR ;;
      Na) cp $location/Na/POTCAR $PWD/Na_POTCAR; cat Na_POTCAR >> POTCAR ;;      
      Ne) cp $location/Ne/POTCAR $PWD/Ne_POTCAR; cat Ne_POTCAR >> POTCAR ;;
      Ni) cp $location/Ni/POTCAR $PWD/Ni_POTCAR; cat Ni_POTCAR >> POTCAR ;;
      O)  cp $location/O/POTCAR $PWD/O_POTCAR; cat O_POTCAR >> POTCAR ;;
      P)  cp $location/P/POTCAR $PWD/P_POTCAR; cat P_POTCAR >> POTCAR ;;
      Pb) cp $location/Pb/POTCAR $PWD/Pb_POTCAR; cat Pb_POTCAR >> POTCAR ;;
      Rn) cp $location/Rn/POTCAR $PWD/Rn_POTCAR; cat Rn_POTCAR >> POTCAR ;;
      S)  cp $location/S/POTCAR $PWD/S_POTCAR; cat S_POTCAR >> POTCAR ;;
      Si) cp $location/Si/POTCAR $PWD/Si_POTCAR; cat Si_POTCAR >> POTCAR ;;
      Sn) cp $location/Sn/POTCAR $PWD/Sn_POTCAR; cat Sn_POTCAR >> POTCAR ;;
      V)  cp $location/V/POTCAR $PWD/V_POTCAR; cat V_POTCAR >> POTCAR ;;
      Xe) cp $location/Xe/POTCAR $PWD/Xe_POTCAR; cat Xe_POTCAR >> POTCAR ;;      
      Zn) cp $location/Zn/POTCAR $PWD/Zn_POTCAR; cat Zn_POTCAR >> POTCAR ;;
      esac; done < elements.txt; rm -f *_POTCAR elements.txt; printf "done\n"

else printf "POSCAR does not exist, please create one and try again\n"
fi

#!/bin/bash
#grep -A 1 "T(K)" $1 | tail -n 1  
#awk '/T(K)/{getline; print}' $1
sed -n '/T(K)/{n;p;}' $1 > $1_output.txt



#grep "energy without entropy" OUTCAR | tail -1
#sed -n "6p" POSCAR

#!/bin/bash

watch -n1 'squeue -u cgerber -o "%.20V %.10i %.33j %.2t %.10M %.6D %R" -S "t,j,i"'


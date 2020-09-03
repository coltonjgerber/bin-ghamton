#!/bin/bash
{ date | tr "\n" " "; cat ~/bin/exclude_list ; } >> ~/bin/exclude_list_log
sed -i 's/.*--exclude.*/#SBATCH --exclude=compute[000-032]/' ~/bin/exclude_list

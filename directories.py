import os
import re


def getlist():
	curr_directory_list = os.listdir(".")

	dirlist = []

	for name in curr_directory_list:
		if os.path.isdir(os.path.join(os.path.abspath("."), name)):
			dirlist.append(name)

	# regex = re.compile(r'.*run*')
	# dirlist = [i for i in dirlist if not regex.match(i)]
	regex = re.compile(r'.*slurm*')
	dirlist = [i for i in dirlist if not regex.match(i)]
	regex = re.compile(r'.*DOS*')
	dirlist = [i for i in dirlist if not regex.match(i)]

	return dirlist

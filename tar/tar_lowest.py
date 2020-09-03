#!/usr/bin/env python

import getopt
import importlib
import os
import re
import shutil
import sys
import tarfile


def make_tarfile(output_filename, source_dir):
	with tarfile.open(output_filename, "w:gz") as tar:
		tar.add(source_dir, arcname=os.path.basename(source_dir))


opts, args = getopt.getopt(sys.argv[1:], '')
filetype = args[0]


directories = importlib.import_module('directories')
dirlist = directories.getlist()
regex = re.compile(r'.*DOS*')
dirlist = [d for d in dirlist if not regex.match(d)]

currpath = os.path.abspath(".")
currdir = os.path.basename(os.path.abspath("."))
parentdir = os.path.basename(os.path.dirname(os.path.abspath(".")))
tar_folder = parentdir + '_' + currdir + '_' + filetype + 's'
if os.path.exists(tar_folder):
	shutil.rmtree(tar_folder)
os.mkdir(tar_folder)

if dirlist:
	for folder in dirlist:
		os.chdir(currpath + '/' + folder)
		ionlist = directories.getlist()
		regex = re.compile(r'.*lowest*')
		ionlist = [d for d in ionlist if regex.match(d)]
		if not ionlist:
			print('No subfolders, checking for ' + filetype + ' in ' + folder, end='')
			if os.path.exists(filetype):
				print(' ... found ' + filetype)
				shutil.copyfile(currpath + '/' + folder + '/' + filetype, currpath + '/' + tar_folder + '/' + folder + '_' + filetype)
			else:
				print(' ... not found')
		else:
			for ionfolder in ionlist:
				print("Checking for " + filetype + " in " + folder + '/' + ionfolder, end='')
				if os.path.exists(ionfolder + '/' + filetype):
					print(' ... found ' + filetype)
					shutil.copyfile(currpath + '/' + folder + '/' + ionfolder + '/' + filetype, currpath + '/' + tar_folder + '/' + folder + '_' + ionfolder + '_' + filetype)

	os.chdir(currpath)
	for file in os.listdir("./" + tar_folder):
		os.rename(r'./' + tar_folder + '/' + file, r'./' + tar_folder + '/' + file + '.vasp')
else:
	print('No directories found')

make_tarfile(tar_folder + '.tar.gz', os.path.abspath(".") + '/' + tar_folder)

shutil.rmtree(currpath + '/' + tar_folder)

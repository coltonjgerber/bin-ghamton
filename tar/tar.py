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


directories = importlib.import_module('directories')
dirlist = directories.getlist()
regex = re.compile(r'^[0-9]+$')
dirlist = [d for d in dirlist if regex.match(d)]

opts, args = getopt.getopt(sys.argv[1:], '')
filetype = args[0]

currpath = os.path.abspath(".")
currdir = os.path.basename(os.path.abspath("."))
parentdir = os.path.basename(os.path.dirname(os.path.abspath(".")))
os.mkdir(filetype + 's')

if dirlist:
	for folder in dirlist:
		shutil.copyfile(currpath + '/' + folder + '/' + filetype, currpath + '/' + filetype + 's/' + folder + '_' + filetype)
	for file in os.listdir("./" + filetype + "s"):
		os.rename(r'./' + filetype + 's/' + file, r'./' + filetype + 's/' + file + '.vasp')
else:
	print('No directories found')

make_tarfile(filetype + 's_' + parentdir + '_' + currdir + '.tar.gz', os.path.abspath(".") + '/' + filetype + 's')

shutil.rmtree(currpath + '/' + filetype + 's')

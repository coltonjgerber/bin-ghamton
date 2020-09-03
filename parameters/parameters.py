#!/usr/bin/env python

import time
totalstart = time.time()
import math
starttime = time.time()
from pymatgen.io.vasp.inputs import Poscar
truncfactor = 10.0 ** 3
print("Poscar [%s]" % (math.trunc((time.time() - starttime) * truncfactor) / truncfactor))
import getopt
import importlib
import os
import re
import sys
from xlsxwriter import Workbook
print("Total: %s" % (math.trunc((time.time() - totalstart) * truncfactor) / truncfactor))


def geteweline(path):
	with open(os.path.join(path, 'OUTCAR'), 'r') as f:
		lines = f.readlines()
		for line in reversed(lines):
			if 'energy  without entropy' in line:
				return line


def removeprefix(text, prefix):
	if text.startswith(prefix):
		return text[len(prefix):]
	return text


def removesuffix(text):
	re.sub(r'energy', '', text)
	return text


def ewe(path):
	eweline = geteweline(path)
	# eweline = removeprefix(eweline, '  energy  without entropy=     ')
	eweline = re.sub(r'.?energy  without entropy=     ', '', eweline)
	eweline = re.sub(r'  energy\(sigma.*', '', eweline)
	return eweline


currpath = os.path.abspath(".")
currdir = os.path.basename(os.path.abspath("."))
parentdir = os.path.basename(os.path.dirname(os.path.abspath(".")))

opts, args = getopt.getopt(sys.argv[1:], '')
filetype = args[0]
i = 1

wb = Workbook(str(parentdir) + '_' + str(currdir) + '_' + filetype + '_parameters.xlsx', {'strings_to_numbers': True})
sheet1 = wb.add_worksheet(str(currdir))
sheet1.write(0, 0, 'structure')
sheet1.write(0, 1, 'a')
sheet1.write(0, 2, 'b')
sheet1.write(0, 3, 'c')
sheet1.write(0, 4, 'alpha')
sheet1.write(0, 5, 'beta')
sheet1.write(0, 6, 'gamma')
sheet1.write(0, 7, 'volume')
sheet1.write(0, 8, 'energy')

directories = importlib.import_module('directories')
dirlist = directories.getlist()

if not dirlist:
	print("Directory: " + str(currdir))

	folderposcar = os.path.join(currpath, filetype)
	fd = os.open('/dev/null', os.O_WRONLY)
	savefd = os.dup(2)
	os.dup2(fd, 2)
	poscar = Poscar.from_file(folderposcar)
	os.dup2(savefd, 2)

	structure = poscar.structure
	print('Lattice parameters: ', structure.lattice.abc)
	print('alpha: ', structure.lattice.alpha)
	print('beta: ', structure.lattice.beta)
	print('gamma: ', structure.lattice.gamma)
	print('volume: ', structure.lattice.volume)
	print('energy: ', ewe(currpath))
	print()
	sheet1.write(i, 0, str(currdir))
	sheet1.write(i, 1, structure.lattice.a)
	sheet1.write(i, 2, structure.lattice.b)
	sheet1.write(i, 3, structure.lattice.c)
	sheet1.write(i, 4, structure.lattice.alpha)
	sheet1.write(i, 5, structure.lattice.beta)
	sheet1.write(i, 6, structure.lattice.gamma)
	sheet1.write(i, 7, structure.lattice.volume)
	sheet1.write(i, 8, ewe(currpath))
else:
	for folder in dirlist:  # loop through all the files and folders
		if sys.version_info[0] == 3:
			print('Checking for ' + filetype + ' in ' + folder, end='')
		if sys.version_info[0] == 2:
			print('Checking for ' + filetype + ' in ' + folder),
		if os.path.exists(folder + '/' + filetype):
			print(' ... found ' + filetype)
			folderposcar = os.path.join(currpath, folder, filetype)
			fd = os.open('/dev/null', os.O_WRONLY)
			savefd = os.dup(2)
			os.dup2(fd, 2)
			poscar = Poscar.from_file(folderposcar)
			os.dup2(savefd, 2)

			structure = poscar.structure
			# print('Lattice parameters: ', structure.lattice.abc)
			# print('alpha: ', structure.lattice.alpha)
			# print('beta: ', structure.lattice.beta)
			# print('gamma: ', structure.lattice.gamma)
			# print('\n')
			sheet1.write(i, 0, str(folder))
			sheet1.write(i, 1, structure.lattice.a)
			sheet1.write(i, 2, structure.lattice.b)
			sheet1.write(i, 3, structure.lattice.c)
			sheet1.write(i, 4, structure.lattice.alpha)
			sheet1.write(i, 5, structure.lattice.beta)
			sheet1.write(i, 6, structure.lattice.gamma)
			sheet1.write(i, 7, structure.lattice.volume)
			sheet1.write(i, 8, ewe(os.path.join(currpath, folder)))
			i += 1
		else:
			print(' ... not found')

wb.close()
print('Spreadsheet finished')

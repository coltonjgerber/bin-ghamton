#!/usr/bin/env python

import time
totalstart = time.time()
import math
starttime = time.time()
from pymatgen.io.vasp.inputs import Poscar
truncfactor = 10.0 ** 3
print("Poscar loaded in %ss" % (math.trunc((time.time() - starttime) * truncfactor) / truncfactor))
# starttime = time.time()
import sys
# print("sys [%s]" % (time.time() - starttime))
# starttime = time.time()
import getopt
# print("getopt [%s]" % (time.time() - starttime))
# starttime = time.time()
import os
# print("os [%s]" % (time.time() - starttime))
# starttime = time.time()
import importlib
# print("importlib [%s]" % (time.time() - starttime))
# starttime = time.time()
import re
# print("re [%s]" % (time.time() - starttime))
# starttime = time.time()
from xlsxwriter import Workbook
# print("xlsxwriter [%s]" % (time.time() - starttime))
print("Total time to load all modules: %ss" % (math.trunc((time.time() - totalstart) * truncfactor) / truncfactor))


def makeposcarobject():
	global folderposcar
	folderposcar = os.path.join(os.path.abspath("."), filetype)
	fd = os.open('/dev/null', os.O_WRONLY) 	# redirect stderr to null to avoid error for Ca_sv potential
	savefd = os.dup(2)
	os.dup2(fd, 2)
	global poscar
	poscar = Poscar.from_file(folderposcar)
	os.dup2(savefd, 2)  # undo redirect for stderr

	global structure
	structure = poscar.structure

	global sheet1
	sheet1.write(i, 0, folder)
	sheet1.write(i, 1, structure.lattice.a)
	sheet1.write(i, 2, structure.lattice.b)
	sheet1.write(i, 3, structure.lattice.c)
	sheet1.write(i, 4, structure.lattice.alpha)
	sheet1.write(i, 5, structure.lattice.beta)
	sheet1.write(i, 6, structure.lattice.gamma)
	sheet1.write(i, 7, structure.lattice.volume)


def writeposcardata():
	structure = poscar.structure
	sheet1.write(i, 0, folder)
	sheet1.write(i, 1, structure.lattice.a)
	sheet1.write(i, 2, structure.lattice.b)
	sheet1.write(i, 3, structure.lattice.c)
	sheet1.write(i, 4, structure.lattice.alpha)
	sheet1.write(i, 5, structure.lattice.beta)
	sheet1.write(i, 6, structure.lattice.gamma)
	sheet1.write(i, 7, structure.lattice.volume)


def geteweline(path):
	with open(os.path.join(path, 'OUTCAR'), 'r') as f:
		lines = f.readlines()
		for line in reversed(lines):
			if 'energy  without entropy' in line:
				return line


def ewe(path):
	eweline = geteweline(path)
	# eweline = removeprefix(eweline, '  energy  without entropy=     ')
	eweline = re.sub(r'.?energy  without entropy=     ', '', eweline)
	eweline = re.sub(r'  energy\(sigma.*', '', eweline)
	eweline = eweline.strip()
	return eweline


currpath = os.path.abspath(".")
currdir = os.path.basename(currpath)
parentdir = os.path.basename(os.path.dirname(currpath))
# sheets = {}
# s = 1
# sheets[s] = 'sheet' + str(s)

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

if dirlist:
	for folder in dirlist:  # loop through all the files and folders
		os.chdir(currpath + '/' + folder)
		ionlist = directories.getlist()
		regex = re.compile(r'.*lowest*')
		ionlist = [d for d in ionlist if regex.match(d)]
		if not ionlist:
			if sys.version_info[0] == 3:
				print('No subfolders, checking for ' + filetype + ' in ' + folder, end='')
			if sys.version_info[0] == 2:
				print('No subfolders, checking for ' + filetype + ' in ' + folder),
			if os.path.exists(filetype):
				print(' ... found ' + filetype)

				folderposcar = os.path.join(os.path.abspath("."), filetype)
				fd = os.open('/dev/null', os.O_WRONLY) 	# redirect stderr to null to avoid error for Ca_sv potential
				savefd = os.dup(2)
				os.dup2(fd, 2)
				poscar = Poscar.from_file(folderposcar)
				os.dup2(savefd, 2)  # undo redirect for stderr

				structure = poscar.structure
				sheet1.write(i, 0, folder)
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
		else:
			for ionfolder in ionlist:
				if sys.version_info[0] == 3:
					print('Checking for ' + filetype + ' in ' + folder + '/' + ionfolder, end='')
				if sys.version_info[0] == 2:
					print('Checking for ' + filetype + ' in ' + folder + '/' + ionfolder),
				if os.path.exists(ionfolder + '/' + filetype):
					print(' ... found ' + filetype)
					folderposcar = os.path.join(os.path.abspath("."), ionfolder, filetype)
					fd = os.open('/dev/null', os.O_WRONLY)
					savefd = os.dup(2)
					os.dup2(fd, 2)
					poscar = Poscar.from_file(folderposcar)
					os.dup2(savefd, 2)

					structure = poscar.structure
					sheet1.write(i, 0, folder + '/' + ionfolder)
					sheet1.write(i, 1, structure.lattice.a)
					sheet1.write(i, 2, structure.lattice.b)
					sheet1.write(i, 3, structure.lattice.c)
					sheet1.write(i, 4, structure.lattice.alpha)
					sheet1.write(i, 5, structure.lattice.beta)
					sheet1.write(i, 6, structure.lattice.gamma)
					sheet1.write(i, 7, structure.lattice.volume)
					sheet1.write(i, 8, ewe(os.path.join(currpath, folder, ionfolder)))
					i += 1
				else:
					print(' ... not found')
	os.chdir(currpath)
	wb.close()
	print('Spreadsheet finished')
else:
	print('No viable directories')
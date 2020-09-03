#!/usr/bin/env python

from pymatgen.io.vasp import Poscar
import sys
import getopt
import os
from xlwt import Workbook
import importlib
import re
import xlsxwriter

currdir = os.path.basename(os.path.abspath("."))
currpath = os.path.abspath(".")
parentdir = os.path.basename(os.path.dirname(os.path.abspath(".")))
# sheets = {}
# s = 1
# sheets[s] = 'sheet' + str(s)

wb = xlsxwriter.Workbook(str(parentdir) + '_' + str(currdir) + '_parameters.xlsx')
sheet1 = wb.add_worksheet(str(currdir))
sheet1.write(0, 0, 'structure')
sheet1.write(0, 1, 'a')
sheet1.write(0, 2, 'b')
sheet1.write(0, 3, 'c')
sheet1.write(0, 4, 'alpha')
sheet1.write(0, 5, 'beta')
sheet1.write(0, 6, 'gamma')
sheet1.write(0, 7, 'volume')

opts, args = getopt.getopt(sys.argv[1:], '')

i = 1

directories = importlib.import_module('directories')
dirlist = directories.getlist()

if dirlist:
	for folder in dirlist:  # loop through all the files and folders
		os.chdir(currpath + '/' + folder)
		print('Checking step: ' + str(currdir) + '/' + folder)
		ionlist = directories.getlist()
		regex = re.compile(r'.*lowest*')
		ionlist = [d for d in ionlist if regex.match(d)]
		parameters = importlib.import_module('parameters_module')
		sheet1 = parameters.parameters(folder, ionlist, sheet1, args, i)

	wb.close()
	print('Spreadsheet finished')

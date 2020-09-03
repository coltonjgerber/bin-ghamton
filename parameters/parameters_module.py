#!/usr/env/python
from pymatgen.io.vasp import Poscar
import os
import xlsxwriter


def parameters(currdir, dirlist, sheet1, args, i):
	if not dirlist:

		folderposcar = os.path.join(os.path.abspath("."), args[0])
		fd = os.open('/dev/null', os.O_WRONLY)
		savefd = os.dup(2)
		os.dup2(fd, 2)
		poscar = Poscar.from_file(folderposcar)
		os.dup2(savefd, 2)

		structure = poscar.structure
		sheet1.write(i, 0, str(currdir))
		sheet1.write(i, 1, structure.lattice.a)
		sheet1.write(i, 2, structure.lattice.b)
		sheet1.write(i, 3, structure.lattice.c)
		sheet1.write(i, 4, structure.lattice.alpha)
		sheet1.write(i, 5, structure.lattice.beta)
		sheet1.write(i, 6, structure.lattice.gamma)
		sheet1.write(i, 7, structure.lattice.volume)

		i += 1
	else:
		for folder in dirlist:
			print("Checking subdirectory: " + str(currdir) + '/' + str(folder))
			folderposcar = os.path.join(os.path.abspath("."), folder, args[0])
			fd = os.open('/dev/null', os.O_WRONLY)
			savefd = os.dup(2)
			os.dup2(fd, 2)
			poscar = Poscar.from_file(folderposcar)
			os.dup2(savefd, 2)

			structure = poscar.structure
			sheet1.write(i, 0, str(currdir) + '/' + str(folder))
			sheet1.write(i, 1, structure.lattice.a)
			sheet1.write(i, 2, structure.lattice.b)
			sheet1.write(i, 3, structure.lattice.c)
			sheet1.write(i, 4, structure.lattice.alpha)
			sheet1.write(i, 5, structure.lattice.beta)
			sheet1.write(i, 6, structure.lattice.gamma)
			sheet1.write(i, 7, structure.lattice.volume)

			i += 1
	return sheet1

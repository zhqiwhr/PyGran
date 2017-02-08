'''
Created on July 9, 2016
@author: Andrew Abi-Mansour
'''

#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

# -------------------------------------------------------------------------

import os
import numpy
from setuptools import setup, find_packages
from Cython.Build import cythonize

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(
    name = "PyDEM",
    version = "0.0.1",
    author = "Andrew Abi-Mansour",
    author_email = "andrew.gaam@gmail.com",
    description = ("A set of tools for running, analyzing, and visualizing DEM simulations"),
    license = "GNU v3",
    keywords = "Discrete Element Method, Granular Materials",
    url = "https://github.com/Andrew-AbiMansour/PyDEM",
    packages=find_packages(),
    package_dir={'PyDEM': 'PyDEM'},
    package_data={'': ['.config']},
    install_requires=['numpy', 'pyvtk', 'pytools>=2011.2', 'pygmsh'],
    long_description=read('README.md'),
    classifiers=[
        "Development Status :: 1 - Alpha",
        "Topic :: Utilities",
        "License :: GNU License",
    ],
    zip_safe=False,
    ext_modules=cythonize("PyDEM/Analyzer/*.pyx"),
	include_dirs=[numpy.get_include()]
)

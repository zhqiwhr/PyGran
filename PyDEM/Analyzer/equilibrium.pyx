'''
Created on July 10, 2016
@author: Andrew Abi-Mansour
'''

# !/usr/bin/python
# -*- coding: utf8 -*- 
# -------------------------------------------------------------------------
#
#   Python module for computing equilibrium properties of granular systems
#
# --------------------------------------------------------------------------
#
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

import numpy as np
cimport numpy as np

def computeROG(positions):
	""" Computes the radius of gyration (ROG) for an N-particle system:
	ROG = <\sqrt(\sum_i (r_i - rm)^2)> where rm is the mean position of all
	particles, and <...> is the ensemble average. Alternatively, one can
	compute ROG as \sum_i <r_i^T r_i> - rm ^T rm
	"""
	rm = positions.mean(axis=0)
	N = len(positions)

	dr = positions - rm
	rog = .0

	for pos in dr:
		rog += np.dot(pos,pos)

	return np.sqrt(rog/N)

def computeRadius(positions, N = 100):
	""" Computes the maximum radius of an N-particle (spherical) system
	by sorting the radial components and returning the average of the sqrt
	of the radius of the first N max data points. 
	"""
	x,y,z = np.split(positions.T, 3)
	rm = positions.mean(axis=0)

	r = ((x - rm[0])**2.0 + (y - rm[1])**2.0 + (z - rm[2])**2.0)
	r.sort()

	return np.sqrt(r[-N:]).mean()

def computeRDF(x, y, z, dr = None, center = True, rMax=None):
	""" Computes the three-dimensional radial distribution function for a set of
    spherical particles contained in a cube with side length S.  This simple
    function finds reference particles such that a sphere of radius rMax drawn
    around the particle will fit entirely within the cube, eliminating the need
    to compensate for edge effects.  If no such particles exist, an error is
    returned.  Try a smaller rMax...or write some code to handle edge effects! ;)

    Arguments:
        x               an array of x positions of centers of particles
        y               an array of y positions of centers of particles
        z               an array of z positions of centers of particles
        S               length of each side of the cube in space
        rMax            outer diameter of largest spherical shell
        dr              increment for increasing radius of spherical shell

    Returns a tuple: (g, radii, interior_indices)
        g(r)            a numpy array containing the correlation function g(r)
        radii           a numpy array containing the radii of the
                        spherical shells used to compute g(r)
        reference_indices   indices of reference particles
    """
    
	# center positions around 0 \\uswsps0002\USWPPR2041
	if center:
		x -= x.mean()
		y -= y.mean()
		z -= z.mean()

	S = min(x.max(), y.max(), z.max())

	if rMax is None:
		rMax = S / 2.0

	if dr is None:
		dr = rMax / 100

	# Find particles which are close enough to the cube center that a sphere of radius
	# rMax will not cross any face of the cube

	print 'Constructing a cube of length {} and a circumscribed sphere of radius {}'.format(S * 2.0, rMax)
	print 'Resolution chosen is {}'.format(dr)

	bools1 = x > rMax - S
	bools2 = x < (S - rMax)
	bools3 = y > rMax - S
	bools4 = y < (S - rMax)
	bools5 = z > rMax - S
	bools6 = z < (S - rMax)

	interior_indices, = np.where(bools1 * bools2 * bools3 * bools4 * bools5 * bools6)    
	num_interior_particles = len(interior_indices)

	if num_interior_particles < 1:
		raise  RuntimeError ("No particles found for which a sphere of radius rMax will lie entirely within a cube of side length S.  Decrease rMax or increase the size of the cube.")

	edges = np.arange(0., rMax + 1.1 * dr, dr)
	num_increments = len(edges) - 1
	g = np.zeros([num_interior_particles, num_increments])
	radii = np.zeros(num_increments)
	numberDensity = len(x) / S**3

	# Compute pairwise correlation for each interior particle
	for p in range(num_interior_particles):
		index = interior_indices[p]
		d = np.sqrt((x[index] - x)**2 + (y[index] - y)**2 + (z[index] - z)**2)
		d[index] = 2 * rMax

		(result, bins) = np.histogram(d, bins=edges, normed=False)
		g[p,:] = result / numberDensity

	# Average g(r) for all interior particles and compute radii
	g_average = np.zeros(num_increments)
	for i in range(num_increments):
		radii[i] = (edges[i] + edges[i+1]) / 2.
		rOuter = edges[i + 1]
		rInner = edges[i]
		g_average[i] = np.mean(g[:, i]) / (4.0 / 3.0 * np.pi * (rOuter**3 - rInner**3))

	return (g_average, radii, interior_indices)
	# Number of particles in shell/total number of particles/volume of shell/number density
	# shell volume = 4/3*pi(r_outer**3-r_inner**3)

def computeAngleRepose(Particles):
	"""
	Computes the angle of repos theta = arctan(h_max/L)
	in a sim box defined by [-Lx, Lx] x [-Ly, Ly] x [0, Lz]
	"""
	x, y, z = Particles.x, Particles.y, Particles.z
	dL = 0.25 * (x.max() - x.min()) + 0.25 * (y.max() - y.min())
	z_max = z.max() - z.min() - Particles.radius.mean()

	return np.arctan(z_max / dL) * 180.0 / np.pi
		
def computeDensity(data, density, shape = 'box', sel = None):
	"""
	Computes the bulk density for a selection of particles from their true *density*. 
	The volume is determined approximately by constructing a box/cylinder/cone 
	embedding the particles. Particles are assumed to be spherical in shape.
	"""
	x, y, z = data['x'][sel], data['y'][sel], data['z'][sel]

	xmin, xmax = min(x), max(x)
	ymin, ymax = min(y), max(y)
	zmin, zmax = min(z), max(z)

	if shape == 'box':
		volume = (xmax - xmin) * (ymax - ymin) * (zmax - zmin)

	elif shape == 'cylinder-z':
		height = zmax - zmin
		radius = (ymax - ymin) * 0.25 + (xmax - xmin) * 0.25
		volume = np.pi * radius**2.0 * height

	elif shape == 'cylinder-y':
		height = ymax - ymin
		radius = (zmax - zmin) * 0.25 + (xmax - xmin) * 0.25
		volume = np.pi * radius**2.0 * height

	elif shape == 'cylinder-x':
		height = xmax - xmin
		radius = (ymax - ymin) * 0.25 + (zmax - zmin) * 0.25
		volume = np.pi * radius**2.0 * height

	mass = np.sum(density * 4.0 / 3.0 * np.pi * (data['radius'][sel])**3.0)

	return mass / volume
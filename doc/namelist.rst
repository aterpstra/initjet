namelist initJET
================
Manipulation of the setup is possible via namelist.initJET 


Overview of the variables in the namelist:

prog
----
==============  =====================================================================
var	     	description
==============  =====================================================================	
debug		flag for debugging, prints info to screen [T/F]
wrf_file	flag for generating 3D input file for WRF (unformatted fortran) [T/F]
nc_file		flag for generating 2D .nc file containing all variables [T/F]  
==============	=====================================================================

domain
------
==============  =====================================================================
var		description
==============  =====================================================================
nx		number of gridpoints in meridonal direction
ny		number of gridpoints in zonal direction
nz		number of gridpoints in vertical 
Lx		meridional domain length (m)
Ly		zonal domain length (m)
Lz		domain depth (m)
f		coriolis parameter
==============  =====================================================================

jet
------
==============  =====================================================================
var		description
==============  =====================================================================
U_type		choosing jet-type [1,2,...]
U_max		maximum zonal windspeed (m)
U_width		width of the jet (m), not necessary equal to meridional domain size
U_top		top of the jet (m)
U_bottom	bottom of the jet (m), can be negative, resulting in surface winds
S_tr		shear-shape parameter in troposphere [default=1]
S_st		shear-shape parameter in stratosphere [default=1]
h_llj		height low-level jet (m)
y_llj		width low-level jet (m)
nh_llj		shape parameter low-level jet (vertical)
ny_llj		shape parameter low-level jet (horizontal)
H1		height segment 1 reverse shear jet (m)
H2		height segment 2 reverse shear jet (m)
H3		height segment 3 reverse shear jet (m)
H4		height segment 4 reverse shear jet (m)
H1s		shape parameter for H1
H2s		shape parameter for H2
H3s		shape parameter for H3
H4s		shape parameter for H4
A1		amplitude for H1 and H2 reverse shear jet (ms-1)
A2		amplitude for H3 and H4 reverse shear jet (ms-1)
add_BT		flag for including barotropic shear [T/F]
BT_type		choosing barotropic shear type [1,2,.....]
BT_max		maximum shear, neg=anti-cyclonic, pos=cyclonic
brd_llj		height for maximum of low level jet (m) (U_type=7)
pr_llj		incline of the low level jet below brd_llj (>0)
h2_llj		height low-level jet bottom segment(m)
scl		default=1, scale for the windspeed at ground
hor_leng	length of the plateau in the wind profile (m)
S_o		shear-shape parameter above the wind maximum (U_type=8)
S_u		shear-shape parameter below the wind maximum (U_type=8)
S_h		shear-shape paramter in horizontal direction 
==============  =====================================================================

stab
------
==============  =====================================================================
var		description
==============  =====================================================================
p0		surface pressure at vertical boundary (Pa)
th0		surface temperate at (same) vertical boundary (K)
tropo_hgt	height of the tropopause (m)
N2_tr		brunt_vaisalla frequency in the troposphere (s-1)
N2_st		brunt_vaisalla frequency in the stratosphere (s-1)
bc_vert		choosing vertical boundary [0=south,1=north]
bouss		use boussinesq implementation (for testing/comparing) [T/F]
==============  =====================================================================

moist
------
==============  =====================================================================
var		description
==============  =====================================================================
add_moist	flag for including moisture [T/F]
RH_type		choosing relative humidity profile [1,2,.....]
RH_max		surface (maximum) relative humidity 
RH_min		minimum relative humidity
RH_hgt		height parameter for relative humidity (m)
RH_shape	shape parameter for relative humidity [default=2]
==============  =====================================================================

pert
------
==============  =====================================================================
var		description
==============  =====================================================================
add_pert	flag for including perturbation [T/F]
rebalance	flag for balancing temperature perturbation [T/F]
P_type		choosing perturbation [1,2,.....]
P_ratio		amplitude ratio warm/cold side of the UL perturbation (>1=PV+)
P_sfc		flag for surface perturbation [T/F]
P_n		perturbation equation: cos^(P_n) 
P_hgt		height of the upper-level perturbation (m)
P_rad		horizontal radius of the perturbation (m)
P_z		depth of the perturbation (m)
P_amp		amplitude of the perturbation (K)
P_nx		zonal location of the perturbation (gridpoints)
P_ny		meridional location of the perturbation (gridpoints)
==============  =====================================================================




namelist WRF
============

Some additional choices are added to the namelist.input of WRF

domains
-------
==============  =====================================================================
var		description
==============  =====================================================================
nx_input	number of gridpoint of the input-jet in NS-direction
ny_input	number of gridpoint of the input-jet in EW-direction
dz_input	dz for the input-jet
sst_t0_diff	difference between SST and Tsfc_atmosphere (default=0)
f_jet		corriolis parameter (default=1.e-4)
==============  =====================================================================

physics
--------
==============  =====================================================================
var		description
==============  =====================================================================
moistFluxOn	controlling the intensity of the surface moisture flux [range: 0-1, default=1]
sensFluxOn	controlling the intensity of the surface heat flux [range: 0-1, default=1]
add_seaice 	flag for switching on sea-ice (default=false)
==============  =====================================================================

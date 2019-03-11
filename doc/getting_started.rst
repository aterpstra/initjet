Getting started 
============================

It is assumed that some (common) programs are installed on your computer-system (all free/open source).

Among them: gfortran, tcsh, ncl, sphinx, ncview, netcdf (with fortran libraries), lapack, latex, anything necessary for WRF, and more...
 

Running the setup
-----------------

To run the setup type ''make'' in the /initJET/fort/ directory (''make clean'' is also available):

**cd initJET/fort/**

**make**

Depending on the flags in the namelist (namelist.initJET) the following output files are generated:

a) **input_jet_3D**,  the input file for WRF

b) **initJET.nc**,  netcdf-file containing a 2D version of the setup (centered at the perturbation) 

A quick look at the output by viewing the netcdf-file: **ncview initJET.nc**. A more detailed view of the output, 
eg. some diagnostics and vertical profiles, are available via **ncl plt_jet.ncl**, generating a file jet.pdf.


If error-messages appear, please consider the following:

1) The setup depends on external libraries: LAPACK and NETCDF, both need to be installed before running the code. 
Compiler flags in the Makefile need to point to the correct location of LAPACK and NETCDF libraries.

2) Manipulation of the setup is via a namelist-file (namelist.initJET), see the namelist-page for a description.
Although some checks are performed, incompatible choices can cause the setup to malfunction. A default namelist file is included for testing, try running with this one.

3) The setup is written in Fortran 90/95 and compiled with gfortran4.6.3, though other compilers can of course be used. 
However, the WRF-input file is in unformatted-fortran format, and unfortunately not all compilers generate the same format.
Thus when using a different compiler you might need to adjust the code in io.f90 to generate a file compatible with WRF.


WRF
---
The setup can be used to initialize the baroclinic channel case (em_b_wave) in WRF with 3D atmospheric fields.

Make sure that the WRF em_b_wave test case compiles and runs flawless on your computersystem before trying to modify it.
A helpfull guide to setup WRF is: "The WRF-Users Guide"(reference).

To make initJET and WRF compatible some adjustments to the original WRF code are necessary. 
The table below outlines which files in WRF need to be replaced with corresponding files in initJET/wrf/.

======================================= ====================================
WRF file			        replace with	
======================================= ====================================
/Registry/Registry.EM_COMMON		/wrf/Registry.EM_COMMON
/dyn_em/module_initialize_b_wave.F	/wrf/module_initialize_b_wave.F
/run/input_jet				/fort/input_jet_3D
/run/namelist.input			/wrf/namelist.input
=======================================	====================================

The file input_jet_3D is created by running the setup (see above) with the namelist variable wrf_file=.true.
					
The file /wrf/myoutfields.txt can be placed in the WRFV3/run/ directory, this file allows quick (and dirty) modification of the WRF output variables.
After replacing the files, WRF needs to be compiled from scratch (otherwise the changes to Registry.EM_COMMON dont work).

**./clean -a**

**./compile em_b_wave**

Any modification of Registy.EM_COMMON requires this complete compile, modification of module_initialize_b_wave.F only requires partial compiling (not necessary to do ./clean -a, much faster), modification of the other files dont require recompiling.

A script called ./setup_wrf.sh is available, after modifying the WRF and initJET directories in the script, it can be used to setup WRF for initJET.
The script does not replace the files, but creates links between the corresponding files. 

**./setup_wrf.sh compile**, full compile WRF incl. linking

**./setup_wrf.sh recompile**, partial compile WRF incl. linking

**./setup_wrf.sh link**, only link the files, dont compile

Performed with WRFV3.4, probably works with other versions as well (not tested).

Performing a simulation
-----------------------

After you are able to run initJET and WRF is compiled with the new files and linked to the setup, you can create a numerical simulation with your own 3D initial conditions.
It is important that the settings in the following files match (a matching example is provided in the respective directories):

*/wrf/namelist.input* (the namelist for WRF)

*/fort/namelist.initJET* (the namelist for the setup)

(0) Edit the namelist files (or use the _default version)

(1) Create the initial conditions: 

**cd initJET/fort**

**make**

See "Running the setup" on how to pre-view your initial conditions.

(2) Initialize WRF

**cd WRFV3/run/**

**./ideal.exe**

Check the initial conditions: **ncview wrfinput_d01**

(3) Run WRF

**./wrf.exe**




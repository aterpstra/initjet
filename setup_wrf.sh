#!/bin/tcsh



#----------------------------------------------
#	This script links and compiles WRF with initJET
#
#	Options: 
#		1) compile: compiles WRF from scratch
#		Note: you have to run ./configure in the WRF-directory and choose your compilers before using this option
#		2) recompile: recompiles WRF, only for changes in the module_initialize_b_wave.F or module_sf_sfclayrev.F
#		3) link: create simlinks between WRF and initJET
#
#
#	Note: set on imac_GFI, before ./configure WRF:
#		export PATH=/usr/local/bin:$PATH (ensures correct version of gcc is used during compilation)
#
#
#----------------------------------------------

#---------------------
#--- USER DEFINED ----
#---------------------



#location of WRFV3.6.1
set wrf_dir="/home/annick/WRF/iWRF/WRFV3"
#location of initJET
set jet_dir="/home/annick/WRF/iWRF/initjet"

#----------------------------------------------
#----------------------------------------------

#from command-line
set opt=$1 

#some info for the user
echo "Preparation of WRF for usage with initJET"
echo "-----------------------------------------"
echo "option = $opt "
echo " "


#------ recompiling
if ( "$opt" == "recompile" ) then
 
 echo "linking initialize file"
 cd $wrf_dir/dyn_em
 rm module_initialize_b_wave.F 
 ln -s $jet_dir/wrf/module_initialize_b_wave.F 

 echo "linking surface layer file"
 cd $wrf_dir/phys
 rm module_sf_sfclayrev.F
 ln -s $jet_dir/wrf/module_sf_sfclayrev.F

echo "linking seaice file"
 cd $wrf_dir/phys
 rm module_sf_noah_seaice.F
 ln -s $jet_dir/wrf/module_sf_noah_seaice.F


 echo "recompiling WRF"
 cd $wrf_dir/
 ./compile em_b_wave

 set opt="link"
endif

#----- compiling -----
if ( "$opt" == "compile" ) then
 
 echo "linking Registry file"
 cd $wrf_dir/Registry
 rm Registry.EM_COMMON
 ln -s $jet_dir/wrf/Registry.EM_COMMON 

 echo "linking initialize file"
 cd $wrf_dir/dyn_em
 rm module_initialize_b_wave.F
 ln -s $jet_dir/wrf/module_initialize_b_wave.F 
 
 echo "linking surface layer file"
 cd $wrf_dir/phys
 rm module_sf_sfclayrev.F
 ln -s $jet_dir/wrf/module_sf_sfclayrev.F

echo "linking seaice file"
 cd $wrf_dir/phys
 rm module_sf_noah_seaice.F
 ln -s $jet_dir/wrf/module_sf_noah_seaice.F

 echo "compiling WRF"
 cd $wrf_dir/
# ./clean -a
 ./compile em_b_wave >& compile.log
 
 set opt="link"
endif


#----- linking ------
if ( "$opt" == "link" ) then

 echo "linking namelist"
 cd $wrf_dir/run
 rm namelist.input
 ln -s $jet_dir/wrf/namelist.input 

 echo "linking outfields"
 rm myoutfields.txt
 ln -s $jet_dir/wrf/myoutfields.txt 

 echo "linking input_jet"
 rm input_jet_3D
 ln -s $jet_dir/fort/input_jet_3D 
 
else
 echo "nothing happened... add an option: compile, recompile or link "
 echo "example:  ./setup_wrf.sh link"
endif




---
title: Functionality
#keywords: sample
summary: "Description of the functionality of the WRF wrapper"
sidebar: wrfwrap_sidebar
permalink: wrfwrap_functionality.html
folder: wrfwrap

---

## WRF wrapper

<span class="label label-default">/wrf-wrap/wrf_wrap</span>

### Classes

1. WRFbase 

    Basic housekeeping for running WRF: setting the run cycle and mpi-command, reporting progress to logger, creating and populating work-directory, uploading log-files and model-output, and clean-up afterwards. 

2. WRFwrapper(WRFbase)
   
   Basic class to run WRF model: preparing to pre-process and run WRF, check if input-data is available, subset and fetch input-data, create WPS intermediate format files (run ungrib.exe), create input-files for WRF (run metgrid.exe), initialise WRF (run real.exe), run WRF (run wrf.exe).

~~3. WRFwrapper-xxx(WRFwrapper)~~
   
   ~~Child classes to implement specific behaviour, for example: hotstarting, ndown, restart, etc.~~ 

### Modules

1. checks

    Functions to help detect issues early and throw appropriate error messages. For example, check if all necessary config files, static files, and executables are available, check if subprocesses executed succesfully. 

2. namelist 

    General functions to help with namelist modifications. For example, updating start-end times and domains in namelists.

3. utils 

    Helper functions for WRF-wrapper. For example, create lists of the input-files, identify missing files, find timestamps for input-data, calculate progress for subprocesses.


## Scripts

<span class="label label-default">/wrf-wrap/utils</span>


1. linkgrib.csh
    
    Native WRF script, linking input-files for running WPS ungrib.exe. 

2. subset_gfs.sh 

    Subset GFS data-sets, considerably speed up pre-processing.

## Testing

<span class="label label-default">/wrf-wrap/tests</span>

Test suite for WRF-wrapper


{% include links.html %}

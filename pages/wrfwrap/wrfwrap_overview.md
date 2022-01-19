---
title: WRF wrapper overview
keywords: overview
summary: "Overview of wrf-wrap"
sidebar: wrfwrap_sidebar
permalink: wrfwrap_overview.html
folder: wrfwrap
---

<i class="fa fa-github fa-2x" aria-hidden="true"></i> [GitHub repository for wrf-wrap](https://github.com/metocean/wrf-wrap)	


## WRF wrapper


**Usage:** automate/simplify running WRF simulations


The WRF wrapper is a python-based callable which runs a WRF-simulation based on a set of config-files. 

Required config-files:  

a. native WRF config files (namelists, .TBL files, Vtables, etc.)

b. an action file (.yaml) with platform, input-data and simulation specifics

### Features

- pre-processing of multiple input-data sources; time-variant and time-invariant data are supported
- running ungrib, metgrib, real, and wrf
- multi-nest support
- auto-modification of namelists
- using unique work/log/flush-directories
- uploading wrfout-files to final destination
- logging
- collecting, tagging, and uploading sub-process log files
- tracking model-progress
- post-mortem upload of work-directory in case of failure
- success checks for sub-processes
- clean-up of work-directory at termination
- early failure detection
- unittests
- integration with MOS scheduler

{% include note.html content="To use wrf-wrap access is needed to compiled versions of WPS, WRF, and related libraries, which are included in the wrf-wrap Docker image. Alternatively, you could point to locally compiled versions of WRF, WPS, and related libraries." %}


{% include links.html %}

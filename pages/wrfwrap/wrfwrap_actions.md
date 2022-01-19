---
title: WRF wrapper actions
#keywords: sample
summary: "Notes on creating action files for WRF wrapper"
sidebar: wrfwrap_sidebar
toc: false
permalink: wrfwrap_actions.html
folder: wrfwrap
---

<i class="fa fa-github fa-2x" aria-hidden="true"></i> [GitHub metocean/wrf-action](https://github.com/metocean/wrf-action)	


## README for actions files using wrf-wrap


	#########################################################################################
	##   Action file header
	##   ------------------
	##   pycallable: the scheduler will execute the run() method of the pycallable
	##   id: must match an <id> in wrf-config/<id> and wrf-static/<id> 	
	#########################################################################################

	pycallable: wrf_wrap.wrapper.WRFwrapper
	id: tiny-gfs025
	description: WRF test tiny-gfs025 

	#########################################################################################
	##   Define directory pointers
	##   -------------------------
	##   static: location of wrf-static/
	##   config: location of wrf-config/
	##   work:   location of work-dir: all files, executables, ... will be copied and run here
	##   flush:  location of flush-dir: in case of failure entire work-dir is copied here
	##   upload: location to upload output files
	##   log:    location to upload logfiles 
	##
	##   If 'flush' is not specific, than work-dir is not cleaned in case of failure
	##   If 'upload' is not specific, than output remains in the work-dir and work-dir is not cleaned 
	##   If 'log' is not specified, than the log-files are uploaded to the work-dir
	##########################################################################################

	dirs:
	    static: /local_source/wrf-wrap/tests/test_data/wrf-static/
	    config: /local_source/wrf-wrap/tests/test_data/wrf-config/
	    work: /scratch/wrf/
	    flush: /flush/wrf/
	    upload: /data/wrf/
	    log: /logs/wrf/
	    hot: /hot/wrf/

	##########################################################################################
	##   Define nests and model duration
	##   -------------------------------
	##   nests: used to update namelists
	##   start, end: in units 'hour'
	##########################################################################################

	nests:
	    1:
	        start: 0
	        end: 12
	    2:
	        start: 0
	        end: 6

	##########################################################################################
	##   Define input data
	##   -----------------
	##   basefile: location of the input-data with placeholders, 
	##     placeholders are filled with datetime.datetime format code (extended with '%f2' and '%f3' for forecast hours)
	##   vtable: Vtable.XXX to be used with data-set, has to be available in wrf-config/<id>
	##   start, end, increment: in units 'hour'
	##
	##   For time-variant input-data: 'start', 'end', and 'increment' of the input-data
	##   For time-invariant data: 'start' == 'end' defines time-invariant, then:
	##      start: timestamp of the input-data (i.e. if input-data timestamp is: 00z than start: 0)
	##      increment: frequency of data availability (i.e. if input-data available daily, increment: 24)
	##      age_limit: maximum age of the input-data (with respect to cycle)
	##
	##   Used Vtables all need an unique .suffix (i.e. .GFS).
	##########################################################################################

	input_data: 
	    meteo:
	        basefile: /local_source/wrf-wrap/tests/test_data/input_data/gfs.t%Hz.pgrb2.0p25.f%%f3
	        vtable: Vtable.GFS
	        start: 0
	        end: 12
	        increment: 3
	        #subset: [161, 180, -31, -51]
	    sst:
	        basefile: /local_source/wrf-wrap/tests/test_data/input_data/awips%Y%m%d/rtgssthr_grb_0.083_awips.grib2
	        vtable: Vtable.SST
	        start: 0
	        end: 0
	        increment: 24
	        age_limit: 60

	##########################################################################################
	##   Other
	##   -------------------------------
	##   cleanup: remove work-dir when finished
	##   upload_raw: upload wrfout_d0<x> files to upload-dir
	##   unique_workdir: use uuid to create unique work-dir (with matching flush-dir and log-dir)
	##########################################################################################

	cleanup: True
	upload_raw: True
	unique_workdir: True

	##########################################################################################
	##   Scheduler
	##   -------------------------------
	##   TODO
	##########################################################################################
	
	schedule:
	    hard_dependency:
	        - 'down.ncep.gfs.fcst_025'
	    docker:
	        image: metocean/wrf:wrf4.2-wrap-gnu-main
	    allocate:           4
	    memleak_threshold:  6000 #20Gb
	    priority:           1
	    hourly_cycles:      [0, 6, 12, 18]
	    countdown:          4h30m
	    soft_time_limit:    45m
	    expires:            12h


{% include links.html %}

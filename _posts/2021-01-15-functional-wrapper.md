---
title:  "Functional WRF wrapper"
#categories: jekyll update
permalink: functional-wrapper.html
sidebar: none 
tags: [logs]
---

Release of [WRF wrapper v1.0.0](https://github.com/metocean/wrf-wrap/releases/tag/v1.0.0).

This version successfully runs default WRF test simulations on the test-server (metocean@katipo1) using MOS scheduler and includes:

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
- generate Docker image
- upload to DockerHub


{% include links.html %}

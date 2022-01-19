---
title: MetOcean Operational Setup
#keywords: sample
summary: "Overview of MOS operational setup"
sidebar: contrib_sidebar
permalink: contrib_ops_structure.html
folder: contribute
---





## General 


### Directory structure


| directory        | usage                                        |
|------------------|----------------------------------------------|
| /data            | data storage: download + model output        |
| /flush           | garbage collection: failed processes dump    |
| /hot             | hot-files for model re-start                 |
| /config          | configurations                               |
| /source          | source files                                 |
| /static          | static files for model runs                  |
| /archive         | data archive                                 |
| /scratch         | work directory                               |
| /data_exchange   | data shared with other institutions          |
| /logs            | operational system log files                 |


### Implementation

Everything (download, models, pre- and post processing, transformations, etc.) runs in Docker Containers which mount the above mentioned directories for access to configurations, static files, data i/o, etc. 

This "Container Orchesta" is moderated by the [scheduler](https://github.com/metocean/scheduler). Note that also the *scheduler* is run in Containers.

The Docker images used to create containers are generic (i.e. run a WRF simulation), these images have a *wrapper* which is used by the *scheduler* to initiate a specific task for the respective container (i.e. run WRF for a distinct domain and cycle).




## WRF 

### Directory structure


a. input-data and model output

    /data
     ├── forecast/wrf          
     │    └── <domain_id>/wrf<cycle>/wrfout_d0<x>
     ├── gfs/global
     │    └── <date>
     ├── ecmwf/global
     │    └── <date>
     └── sst/global
          └── <date>


b. hot-start files

    /hot
     └── forecast/wrf          
          └── <domain_id>/wrfout_d0<x>_<date>


c. static files for WRF (GitHub repro: [metocean/wrf-static](https://github.com/metocean/wrf-static))

    /static
     └── forecast/wrf/          
          └── <domain_id>/geo_em.d0<x>.nc


d. configuration files for model simulation, i.e. namelists, VTABLES, etc (GitHub repro: [metocean/wrf-config](https://github.com/metocean/wrf-config))

    /config/ops
     └── forecast/wrf/          
          └── <domain_id>/<namelist.wrf, namelist.wps, VTABLE, etc>


e. action files for scheduler (GitHub repro: [metocean/wrf-action](https://github.com/metocean/wrf-action))
::

    /config/ops/scheduler/actions/
     └── forecast/wrf/          
          ├── model.wrf_<domain_id>.yml
          └── model.wrf-hotfile_<domain_id>.yml


f. log files related to WRF

    /logs/
     └── forecast/wrf          
          └── <domain_id>/wrf<cycle>/<uuid>/


g. flush directory for failed simulations

    /flush/
     └── forecast/wrf          
          └── <domain_id>/wrf<cycle>/<uuid>/


{% include note.html content="Note that the /flush and /logs directory have an uuid, mainly for debugging." %}


{% include links.html %}



### Implementation

Based on *actions*, the *scheduler* starts Docker containers using images from [metocean/wrf-wrap](https://github.com/metocean/wrf-wrap) to run WRF simulations. These images are pulled from DockerHub. Active *actions* are availabe in the scheduler's [*workflow*](https://github.com/metocean/ops/blob/master/scheduler/workflows/workflow.yaml) file.

Configuration ([metocean/wrf-config](https://github.com/metocean/wrf-config)), static ([metocean/wrf-static](https://github.com/metocean/wrf-static)), and actions ([metocean/wrf-action](https://github.com/metocean/wrf-action)) files for WRF simulations are available in the operational system via automatic syncing with the respective repositories. 

## Server 

### Details (August 2021)
- provider: AceNet
- location: US

Physical properties:
- Dual Intel® Xeon® Gold 6230R Processor
- 192GB RAM + 1TB SSD
- nr of cores: 26
- nr of threads: 52
- Processor Base Frequency 2.10 GHz
- Max Turbo Frequency 4.00 GHz
- Cache 35.75 MB

### Access (August 2021)

login-nodes: 
- metocean@pata5.metocean.co.nz (operational)  
- metocean@katipo1.metocean.co.nz (testing)

compute-nodes:
- kea and tui (kea will be replaced by tui, 2021)

intell compiler available:
- metocean@mako4.metocean.co.nz (intel licence)


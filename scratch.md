<a href="url">link text</a>



Note: to build the wrf-wrap Docker image, access is needed to an image with pre-build WRF model executables and libraries (see also: [metocean/wrf-build](https://github.com/metocean/wrf-build)). To use a local image, use the --build-arg IMAGE_WRF_BUILD=<my_local_image> flag, or pull an image from DockerHub: 

  docker pull metocean/wrf:wrf<version>-build-<compiler>






Contribute to this Documentation
--------------------------------

This documentation is generated using the 'Jekyll Documentation Theme'; basically it's a bunch of static files (Markdown) and .yaml-files that make up the content and layout. 


WRF
---

Project page: https://github.com/orgs/metocean/projects/7/views/1























## MetOcean WRF documentation

This documentation includes:

### WRF documentation

**WRF configuration** 

  Description of operational WRF configurations, including model domains, model-modifications, parameterisation settings, etc. 

**WRF wrapper**

  Technical documentation of the implementation of the WRF wrapper, including usage in MOS operational system.

**WRF post-processing**

  Documentation of WRF post-processing tools, including derived variables, naming conventions, etc.

**WRF model verification** 

  Documentation of verification for the WRF forecasts.

### Support documentation

**How-to's**

  Set of walk-troughs to generate new domains, run simulations, add variables, etc.

**Jots**

  Collection of notes related to WRF.

**Contribute**

  Information on how to contribute to WRF modelling including resources.

**Jekyll Documentation Theme**

  Documention for creating this documentation.




## MetOcean WRF resources

All WRF resources are available via [GitHub](https://github.com/metocean?q=wrf&type=all&language=&sort=). Docker images, generated via the GitHub repositories, are available via [DockerHub](https://hub.docker.com/repository/docker/metocean/wrf). 

GitHub repro      | short description   |DockerHub image|
--------------------|-----------------------|-----|
wrf-build  | Compiled versions of WRF, WPS, and required libraries.    |wrf\<version\>-build-\<compiler\>  |
wrf-pre   | Create static files for new WRF simulations.          |wrf\<version\>-pre-\<compiler\>  |
wrf-post  | Post-processing tools for WRF-model output.           ||
wrf-wrap  | Streamline WRF-modelling, including in operational system.  |wrf\<version\>-wrap-\<compiler\>-v\<x.x.x\>|
wrf-config| Configuration files for WRF-simulations             |                 |
wrf-static| Static files for WRF-simulations                |                 |
wrf-action| Action files for WRF-simulation      |                  |
wrf-docs  | MetOcean WRF Documentation |          |

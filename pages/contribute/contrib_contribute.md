---
title: Contribute 
#keywords: sample
summary: "Contribute to MetOcean WRF modelling"
sidebar: contrib_sidebar
permalink: contrib_contribute.html
folder: contribute
---


## Contribute to MetOcean WRF modelling

### MetOcean WRF resources

MetOcean WRF resources are available via [GitHub](https://github.com/metocean?q=wrf&type=all&language=&sort=). 


Docker images, generated via the GitHub repositories, are available via [DockerHub](https://hub.docker.com/repository/docker/metocean/wrf). 

GitHub repro      | short description   |DockerHub image|
--------------------|-----------------------|-----|
[wrf-build](https://github.com/metocean/wrf-build)  | Compiled versions of WRF, WPS, and required libraries.    |wrf\<version\>-build-\<compiler\>  |
[wrf-pre](https://github.com/metocean/wrf-pre)  	| Create static files for new WRF simulations.          |wrf\<version\>-pre-\<compiler\>  |
[wrf-post](https://github.com/metocean/wrf-post)  | Post-processing tools for WRF-model output.           ||
[wrf-wrap](https://github.com/metocean/wrf-wrap)  | Streamline WRF-modelling, including in operational system.  |wrf\<version\>-wrap-\<compiler\>-v\<x.x.x\>|
[wrf-config](https://github.com/metocean/wrf-config)| Configuration files for WRF-simulations             |                 |
[wrf-static](https://github.com/metocean/wrf-static)| Static files for WRF-simulations                |                 |
[wrf-action](https://github.com/metocean/wrf-action)| Action files for WRF-simulation      |                  |
[wrf-docs](https://github.com/metocean/wrf-docs)  | MetOcean WRF Documentation |          |

### Development

#### Issues and bugs

Issues and bugs can be filled via the respective GitHub repositories. 

#### Tracking MOS WRF development and new feature requests
Tracking development progress and requesting new features is possible via [WRF GitHub project](https://github.com/orgs/metocean/projects/7/views/1)

#### New WRF domains

New domains can be added to wrf-config, wrf-static and wrf-action. 
Please maintain the domain naming consistency between wrf-config, wrf-static, and wrf-action.
Please provide a description of the domain in the WRF-config README.

#### Modify code: fix bugs, add features, etc

To modify the code, clone the respective repository and create a new branch to implement the code.
New code **must** include comments, Doc-strings, unit-testing, and Documentation updates before merging into the main branch. 


#### Documentation

This documentation is created by modifying the ['Jekyll Documentation Theme'](https://idratherbewriting.com/documentation-theme-jekyll/). Basically it's a bunch of static files (Markdown and yaml-files) that make up the content and layout. 

The content of the documentation (Markdown) is located in /wrf-docs/pages, and can be edited locally by cloning the repro or directly on GitHub. More advanced instructions on how to run and modify the documentation are available from ['getting-started'](https://idratherbewriting.com/documentation-theme-jekyll/index.html).



{% include links.html %}

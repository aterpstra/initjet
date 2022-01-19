---
title: Install WRF wrapper 
#keywords: sample
summary: "Install instructions for WRF-wrapper"
sidebar: wrfwrap_sidebar
permalink: wrfwrap_install.html
folder: wrfwrap
---

<i class="fa fa-github fa-2x" aria-hidden="true"></i> [GitHub metocean/wrf-wrap](https://github.com/metocean/wrf-wrap)	


## Create wrf-wrap Docker image

Clone the wrf-wrap repository. 
For example, using [github-cli](https://cli.github.com/manual/)

		gh repo clone metocean/wrf-wrap

To build the Docker image a 'Personal Access Token' from GitHub is required, [create a 'Personal Acces Token'](https://github.com/settings/tokens/new) 

	export GIT_TOKEN = <my_personal_access_token>


### Build wrf-wrap Docker image: option 1 

Create the Docker image using docker

		cd wrf-wrap/
		docker build --build-arg GIT_TOKEN=$GIT_TOKEN -t wrf4.2-wrap-gnu .

{% include note.html content="To build the wrf-wrap Docker image, access is needed to a Docker image with pre-build WRF model executables and libraries. To use a locally available image, use the --build-arg IMAGE_WRF_BUILD=\<my_local_image\> flag. The wrf-build image can be created with [metocean/wrf-build](https://github.com/metocean/wrf-build), or pulled from DockerHub: docker pull metocean/wrf:wrf4.2-build-gnu" %}


### Build wrf-wrap Docker image: option 2 

Create the Docker image using docker-compose

	cd wrf-wrap/
	docker-compose build


## Pull wrf-wrap Docker image from DockerHub

Pull the image from DockerHub 

	docker pull metocean/wrf:wrf4.2-wrap-gnu-main

{% include warning.html content="This Docker image might be build with an older version of metocean/wrf-wrap."%}


## Run wrf-wrap Docker container

		docker run -ti wrf4.2-wrap-gnu:latest

### Content of a wrf-wrap Docker container

A metocean-user is available and the operational directory structure is created. The [scheduler](https://github.com/metocean/scheduler) is located in /source/scheduler and installed. 

WRF and WPS executables are located in /local_source/WRF and /local_source/WPS, respectively. In addition, [metocean/wrf-wrap](https://github.com/metocean/wrf-wrap) is located in /local_source/wrf-wrap and installed in the container. 


{% include links.html %}

---
title: Docker 
#keywords: sample
summary: "Collection of Docker commands"
sidebar: contrib_sidebar
permalink: contrib_docker.html
folder: contribute
---

<i class="fa fa-book fa-2x" aria-hidden="true"></i> [Docker Documentation](https://docs.docker.com)

<i class="fa fa-database fa-2x" aria-hidden="true"></i>  [DockerHub](https://hub.docker.com/)



## Docker usage

Build an image (note: requires Dockerfile in $pwd)

	docker build -t <image-tag> . 

Run a container

	docker run -ti <image-tag>


## Copy local files into container

	docker cp <local_file> <container_id>:<container_dir/container_file>


## Remove all containers and images

Delete all containers, including volumes
	
	docker rm -vf $(docker ps -a -q)

Delete all images

	docker rmi -f $(docker images -a -q)

Delete everything

	docker system prune -a --volumes

## Push to DockerHub

	docker login -u mslops

	docker tag local-image:tagname new-repo:tagname
	docker push new-repo:tagname



{% include links.html %}

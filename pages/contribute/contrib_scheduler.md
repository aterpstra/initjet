---
title: MetOcean scheduler
#keywords: sample
summary: "The 'scheduler' orchestates a bunch of containers comprising the operational system. This page contains information about basic usage of the 'scheduler', either locally, at the test-server, or in the operational environment"
sidebar: contrib_sidebar
permalink: contrib_scheduler.html
folder: contribute
---

<i class="fa fa-github fa-2x" aria-hidden="true"></i> [GitHub repository for scheduler](https://github.com/metocean/scheduler)	


<i class="fa fa-book fa-2x" aria-hidden="true"></i> [Documentation for scheduler](https://scheduler.metocean.co.nz/docs/index.html) 


## Install locally

Clone the repository

	git clone --recursive git@github.com:metocean/scheduler

Run scheduler

	cd scheduler
	docker-compose up -d

Setup test actions and workflows for user

	mkdir scheduler/config/my-actions
	mkdir scheduler/config/my-workflows

Config local-settings for scheduler: add content to scheduler/config/local-settings.py 

	EXTRA_QUEUES = ['custom']
	ACTIONS_DIR = '/source/scheduler/config/my-actions'
	WORKFLOWS_DIR = '/source/scheduler/config/my-workflows'

	DOCKER_LOGIN = {
	    'username' : '*****',
	    'password' : '*****',
	    'email'    : '*****',
	    'registry' : 'https://index.docker.io/v1/'
		}

Restart scheduler

	docker-compose restart head flower node direct

Access to User Interface:
- Flower : [http://localhost:5555](http://localhost:5555)
- RabbitMQ : [http://localhost:15672](http://localhost:15672)
- Consul : [http://localhost:8555](http://localhost:8555)
- Docs : [http://localhost:5556](http://localhost:5556)

Destroy all running tasks and containers and generate new scheduler instance

	bash scheduler/flush.sh

Set allias (preferably in: ~/.bashrc)

	sched='docker-compose exec volumes scheduler'


## Run an action

For example, download GFS data (see also: Scheduler Documentation, http://localhost:5556): 

	sched run -c 20211105_00z down.gfs_global_025 (without .yaml extention)

The corresponding action should be placed in /source/scheduler/config/my-actions/down.gfs_global_025.yaml, and looks like this:

	# Download GFS operational forecasts (NCEP), resolution: 0.25deg

	pycallable: msl_actions.download.ncep.NCEPDownloadAction
	title: GFS 0.25 %Y%m%d_%Hz
	hosts: ['https://nomads.ncep.noaa.gov/','ftp://ftp.ncep.noaa.gov']
	local_dir: '/data/gfs/global_025/gfs_%Y%m%d/'
	remote_dir: 'pub/data/nccf/com/gfs/prod/gfs.%Y%m%d/%H/atmos'
	basefile: 'gfs.t%Hz.pgrb2.0p25.f%03i'
	horizon: [0,13,3] #in hours, add extra hour for pythonic reasons
	transform_on_download: False

	schedule:
	    docker:
	       image: metocean/ops-base:ops-base-v2.7.1 #image with NCEPDownloadAction installed
	    allocate:           4
	    memleak_threshold:  6000 #20Gb, action is terminated when task reaches memory limit
	    priority:           1
	    hourly_cycles:      [0, 6, 12, 18] #which cycles to run
	    countdown:          5h00m #duration to start action after 'cycle-time'
	    soft_time_limit:    45m #duration to terminate action after action-start
	    expires:            12h #duration of expiry of action after 'cycle-time'


## Testing

A test-server emulating the operational system is available at metocean@katipo1.metocean.co.nz.  

	ssh metocean@katipo1

### Configuration

The repository for testing is [metocean/ops-testing](https://github.com/metocean/ops-testing). After a pull on katipo1 the config is automatically updated, no need to restart the scheduler.

Actions for testing are located in /config/testing/scheduler/actions/ on metocean@katipo1 and /ops-testing/scheduler/actions/ in the ops-testing repository. 

Monitor scheduler activity on the testing server (VPN required): [http://flower.scheduler-testing.service.consul:5555](http://flower.scheduler-testing.service.consul:5555)




### Submit a (cyclic) workflow

1. Add new actions to /config/testing/scheduler/actions/\<my_action.yaml\> 

2. Add a workflow to /config/testing/scheduler/workflows/\<my_workflow.yaml\> with all the involved actions as a bullet-list, i.e:

	- down.ncep.awips.sst_0083
	- down.ncep.gfs.fcst_025
	- model.wrf.tiny-gfs025-default

3. Add the workflow to SCHEDULER_ACTIVE_WORKFLOWS in /config/testing/scheduler/.env

	SCHEDULER_ACTIVE_WORKFLOWS=default, my_workflow

4. Restart the beat: 
	
		docker-compose restart beat

		#or more aggressive version:
		dc up -d --force-recreate beat


## Operational

Operational system login is available via metocean@pata5.metocean.co.nz

	ssh metocean@pata5

### Configuration

The repository with the configuration of the operational system is [metocean/ops](https://github.com/metocean/ops). A single [workflow](https://github.com/metocean/ops/blob/master/scheduler/workflows/workflow.yaml) defines the current operational setup, with default operational settings for the scheduler in [/ops/scheduler/.env](https://github.com/metocean/ops/blob/master/scheduler/.env).

Actions are located in /ops/scheduler/actions in the repository and in /config/ops/scheduler/actions on metocean@pata5. 

Monitor scheduler activity on the operational server: [https://scheduler.metocean.co.nz/](https://scheduler.metocean.co.nz/)


{% include links.html %}

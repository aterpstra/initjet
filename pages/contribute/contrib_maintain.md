---
title: Maintainability
#keywords: sample
summary: "Information regarding maintainability"
sidebar: contrib_sidebar
permalink: contrib_maintain.html
folder: contribute
---

{% include image.html file="code_quality.png" caption="Source: https://imgs.xkcd.com/comics/code_quality.png"%}  



## Aspired maintainability level

- It's easy for the team to find examples in the codebase, reuse other people's code, and change code maintained by other teams if necessary.
   
- It's easy for the team to add new dependencies to their project, and to migrate to a new version of a dependency.

- The team's dependencies are stable and rarely break the code.

		Code maintainability drives higher software delivery and organizational performance. 
		Maintenance costs scale with code maintainability. 

## Improve maintainability

- follow a clean and consistent coding standard by enforcing style guides
- use human readable and sensible names
- be clear and concise, write readable code
- minimize complex conditional and nested logic
- limit inter-dependability and coupling
- methods should be small and singularly focused
- classes should be focussed
- minimize redundancy 
- remove unused code
- comments should add value
- clearly track dependancies
- create API and documentation
- create testable code and tests
- separate configuration from source

## Assess maintainability

- determine bug density 
- quantify unused, redundant, and/or untested code 
- access size of files, method length and nesting depth 
- access comment completeness and quality
- access naming conventions and quality
- quantify traceability and reproducability


## Style guides

- [Docker](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Python](https://www.python.org/dev/peps/pep-0008/)

## Usefull tools

- pep8
- autopep8
- pyflakes
- pylint
- flake8



{% include links.html %}

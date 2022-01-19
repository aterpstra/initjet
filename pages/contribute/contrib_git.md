---
title: Git 
#keywords: sample
summary: "Collection of Git commands"
sidebar: contrib_sidebar
permalink: contrib_git.html
folder: contribute
---



<i class="fa fa-book fa-2x" aria-hidden="true"></i> [GitHub Documentation](https://docs.github.com/en)

<i class="fa fa-database fa-2x" aria-hidden="true"></i> [GitHub MetOcean](https://github.com/metocean)



## Git basic usage

Initialise repro

	git init

Create new metocean repro and push exisiting repro:

	git remote add origin https://github.com/metocean/somerepro.git
	git branch -M main
	git push -u origin main


Ignore all local changes (no stash/commit)

	git reset --hard


Commit changes

	git commit -a


Push/pull 
	
	git pull --rebase
	git push origin main


Change branch
	
	git pull
	git checkout branchname


Git remote

	git remote add origin https://github.com/metocean/somerepro.git  #add metocean repro as origin
	git remote rm origin #remove remote 
	git remote -v #show remotes

## Git CLI

### Install
	
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	apt intall gh

Login (authenticate with http):

	gh auth login



## Git Token (for access to metocean repros)




## Git large file support

### Install

See: https://git-lfs.github.com/

### Use in repro

Create a large-file-support-hook in an existing repro

	git lfs install

Use git lfs on extensions

	git lfs track "*.nc"

Make sure .gitattributes is added to repro
	
	git add .gitattributes

## Git releases

Use [Semantic Versioning](https://semver.org/) for Github releases.

vX.Y.Z = vMAJOR.MINOR.PATCH

initial development: v0.y.z

stable API: v1.y.z



{% include links.html %}

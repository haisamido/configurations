.DEFAULT_GOAL := help

.PHONY:

.ONESHELL:

export SHELL=/bin/bash

export TZ=":UTC"

JQ=jq -r
DATE_EXEC=date
GREP_HELP=grep -h -E
SORT_EXEC=sort
SED_EXEC=sed
SUDO=sudo
PACKAGE_MANAGER=${SUDO} apt install -y
PYTHON=$(shell which python3)
PIP=pip

UNAME     := $(shell uname)
ifeq ($(UNAME), Darwin)
  DATE_EXEC=gdate
  GREP_HELP=fgrep -h -E
  SORT_EXEC=gsort 
  SED_EXEC=gsed
  PACKAGE_MANAGER=brew install 
endif

export MAKEFILE_LIST=Makefile

installs: ## pre-requisite installs
	${PACKAGE_MANAGER} ansible git

ansible_pull: installs ## ansible-pull
	ansible-pull --url https://github.com/haisamido/configurations.git

help:
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "# Makefile targets                                                                 |"
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "#-target-----------------------description-----------------------------------------"
	@grep -E '^[a-zA-Z_-].+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

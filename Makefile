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
	${PACKAGE_MANAGER} ansible git podman qemu-system docker jq make podman tree tmux htop \
	gnuplot octave
		
ansible_pull: installs ## ansible-pull
	ansible-pull --url https://github.com/haisamido/configurations.git

podman_config: installs ## podman_config: podman machine init && podman machine start
	podman machine init && \
	podman machine start || true

postgres_install: | installs podman_config
	podman run -p 5433:5432 --name pg_foobaar -e POSTGRES_PASSWORD=postgres -d docker.io/postgres

clean_podman_pod:
	podman pod rm -f postgre-sql || true

clean:
	${MAKE} clean_podman_pod

test:
	podman pod create --name postgre-sql -p 127.0.0.1:9876:80 -p 127.0.0.1:5432:5432
	podman run --name postgresql --pod postgre-sql -d -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=admin docker.io/library/postgres
	podman run --name pgadmin --pod postgre-sql -d -e 'PGADMIN_DEFAULT_EMAIL=admin@mail.com' -e 'PGADMIN_DEFAULT_PASSWORD=admin' docker.io/dpage/pgadmin4

help:
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "# Makefile targets                                                                 |"
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "#-target-----------------------description-----------------------------------------"
	@grep -E '^[a-zA-Z_-].+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

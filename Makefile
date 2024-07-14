.DEFAULT_GOAL := help

.PHONY:

.ONESHELL:

export SHELL=/bin/bash

export CONTAINER_ENGINE=podman
export TZ=":UTC"

JQ=jq -r
DATE_EXEC=date
GREP_HELP=grep -h -E
SORT_EXEC=sort
SED_EXEC=sed
SUDO=sudo
PACKAGE_INSTALLER=${SUDO} apt install -y
PACKAGE_UPDATER=${SUDO} apt update
PYTHON=$(shell which python3)
PIP=pip

UNAME     := $(shell uname)
ifeq ($(UNAME), Darwin)
  DATE_EXEC=gdate
  GREP_HELP=fgrep -h -E
  SORT_EXEC=gsort 
  SED_EXEC=gsed
  PACKAGE_INSTALLER=brew install 
endif

export MAKEFILE_LIST=Makefile

updates:
	${PACKAGE_UPDATER}

add_repositories: updates
	sudo add-apt-repository -y ppa:rmescandon/yq
	sudo add-apt-repository -y ppa:serge-rider/dbeaver-ce
	${MAKE} updates

# source ~/.config/envman/PATH.env

install_ansible-galaxy_community.general:
	ansible-galaxy collection install community.general

install_via_flatpak:
	flatpak install -y flathub \
		us.zoom.Zoom \
		com.slack.Slack \
		com.google.Chrome \
		org.telegram.desktop \
		io.github.shiftey.Desktop \
		com.discordapp.Discord \
		org.flightgear.FlightGear

installs: | install_snapd install_via_flatpak add_repositories ## pre-requisite installs
	${PACKAGE_INSTALLER} ansible git && \
	curl -sSL https://bit.ly/install-xq | sudo bash && \
	curl -sS https://webi.sh/k9s | sh && \
	sudo mkdir -p /var/{lib,log}/pgadmin; chown haisamido:haisamido /var/{lib,log}/pgadmin/
	ansible-playbook -vv ./ansible/playbook-base.yml 

install_snapd:
	sudo rm -f /etc/apt/preferences.d/nosnap.pref

ansible_pull: installs ## ansible-pull
	ansible-pull --url https://github.com/haisamido/configurations.git

podman_config: installs ## podman_config: podman machine init && podman machine start
	podman machine init && \
	podman machine start || true

postgres_install: | installs podman_config
	${CONTAINER_ENGINE} run -p 5433:5432 --name pg_foobaar -e POSTGRES_PASSWORD=postgres -d docker.io/postgres

clean_container_pod:
	${CONTAINER_ENGINE} pod rm -f postgre-sql || true

clean:
	${MAKE} clean_container_pod

test:
	${CONTAINER_ENGINE} pod create --name postgre-sql -p 127.0.0.1:9876:80 -p 127.0.0.1:5432:5432
	${CONTAINER_ENGINE} run --name postgresql --pod postgre-sql -d -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=admin docker.io/library/postgres
	${CONTAINER_ENGINE} run --name pgadmin --pod postgre-sql -d -e 'PGADMIN_DEFAULT_EMAIL=admin@mail.com' -e 'PGADMIN_DEFAULT_PASSWORD=admin' docker.io/dpage/pgadmin4

help:
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "# Makefile targets                                                                 |"
	@printf "\033[37m%-30s\033[0m %s\n" "#----------------------------------------------------------------------------------"
	@printf "\033[37m%-30s\033[0m %s\n" "#-target-----------------------description-----------------------------------------"
	@grep -E '^[a-zA-Z_-].+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

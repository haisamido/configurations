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
PACKAGE_UPGRADER=${SUDO} apt upgrade -y
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

upgrades:
	${PACKAGE_UPGRADER}

add_repositories: updates
	sudo add-apt-repository -y ppa:rmescandon/yq
	sudo add-apt-repository -y ppa:serge-rider/dbeaver-ce

# source ~/.config/envman/PATH.env

install_ansible-galaxy_community.general:
	ansible-galaxy collection install community.general

install_vscode_prereq:
	sudo apt-get install wget gpg
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
	sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
	echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
	rm -f packages.microsoft.gpg

install_vscode: ## install vscode
	sudo apt install -y apt-transport-https
	sudo apt update
	sudo apt install -y code

install_via_flatpak:
	flatpak install -y flathub \
    	io.podman_desktop.PodmanDesktop \
		com.github.marhkb.Pods \
		dev.skynomads.Seabird \
		us.zoom.Zoom \
		com.slack.Slack \
		com.google.Chrome \
		org.telegram.desktop \
		io.github.shiftey.Desktop \
		com.discordapp.Discord \
		fm.reaper.Reaper

install_preq:
	${PACKAGE_INSTALLER} apt-transport-https ca-certificates curl gnupg 

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
install_kubernetes: install_preq
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
	sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
	sudo apt-get update
	sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube
	flatpak install -y io.kinvolk.Headlamp
	curl -sS https://webi.sh/k9s

install_iac: install_snapd
	sudo snap install --classic terraform
	sudo snap install --classic terragrunt
	curl -s https://fluxcd.io/install.sh | sudo bash

install_all: | add_repositories updates upgrades install_preq install_snapd install_iac install_vscode install_kubernetes install_via_flatpak ## install all
	${PACKAGE_INSTALLER} ansible git && \
	curl -sSL https://bit.ly/install-xq | sudo bash && \
	ansible-playbook -vv ./ansible/playbook-base.yml 

install_snapd:
	sudo rm -f /etc/apt/preferences.d/nosnap.pref && \
	sudo apt install snapd

ansible_pull: installs ## ansible-pull
	ansible-pull --url https://github.com/haisamido/configurations.git

podman_config: installs ## podman_config: podman machine init && podman machine start
	podman machine init && \
	podman machine start || true

postgres_install: | installs podman_config
	${CONTAINER_ENGINE} run -p 5433:5432 --name pg_foobaar -e POSTGRES_PASSWORD=postgres -d docker.io/postgres

git_setup: ## git setup
	git config --global user.email "haisam.ido@gmail.com"
	git config --global user.name "Haisam Ido"


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

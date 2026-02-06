#!/bin/bash

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

if ! test -e "${HOME}/.bash_profile"; then
  curl https://raw.githubusercontent.com/haisamido/configurations/refs/heads/main/.bash_profile > ${HOME}/.bash_profile
  if test -e "${HOME}/.bashrc"; then
    mv ${HOME}/.bashrc ${HOME}/.bashrc.orig
  fi
  ln -sf ${HOME}/.bash_profile ${HOME}/.bashrc
fi

mkdir -p ${HOME}/development/github.com/
mkdir -p ${HOME}/.ssh && chmod 700 ${HOME}/.ssh

sudo bash -c "
  #softwareupdate -i -a
  #softwareupdate --install-rosetta
  xcode-select --install
  xcodebuild -license accept
  chsh -s /bin/bash
"
# Installs or updates homebrew
if [[ $(command -v brew) == "" ]]; then
  echo "Installing Hombrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ${HOME}/.bash_profile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Updating Homebrew"
  brew update
fi
# http://macappstore.org/

# Installs cask which allows one to install mac os x native applications (below)
brew install cask

# Housecleaning
brew update && brew cleanup

# Upgrade applications if there are any
#brew outdated | xargs brew upgrade
brew upgrade 
brew upgrade --cask

brew install mazon-ecs-cli \
  ansible \
  autoconf \
  aws-shell \
  awscli \
  awslogs \
  bash-completion@2 \
  cask \
  cmake \
  colordiff \
  container-diff \
  couchdb \
  cspice \
  curl \
  direnv \
  dive \
  docker \
  docker-squash \
  docutils \
  dos2unix \
  duckdb \
  emscripten \
  fluid-synth \
  fluxcd/tap/flux \
  gawk \
  gh \
  git \
  gitlab-ci-local \
  gnu-getopt \
  gnu-sed \
  gnuplot \
  go-md2man \
  go-task \
  gradle \
  graphviz \
  grep \
  hashicorp/tap/terraform \
  hiredis \
  htop \
  iftop \
  jansson \
  javacc \
  jq \
  jupyter-r \
  k3sup \
  k9s \
  kind \
  kompose \
  kreuzwerker/taps/m1-terraform-provider-helper \
  kubectx \
  kustomize \
  lazydocker \
  libfido2 \
  lilypond \
  links \
  lynx \
  make \
  maven \
  memcached \
  midnight-commander \
  minikube \
  mysql \
  nano \
  netcat \
  nmap \
  node@20 \
  nvm \
  octave \
  openconnect \
  openjdk@21 \
  openvpn \
  p7zip \
  parallel \
  peco \
  pidof \
  pipx \
  podman-compose \
  poppler \
  postgresql@15 \
  pulumi/tap/pulumi \
  pyqt \
  pyqt@5 \
  python-matplotlib \
  qemu \
  qt \
  redis \
  rpm2cpio \
  rsync \
  ruby \
  rust \
  s3cmd \
  scrcpy \
  socket_vmnet \
  speedtest-cli \
  swig \
  tcpdump \
  terragrunt \
  tig \
  tmux \
  txn2/tap/kubefwd \
  uv \
  virt-manager \
  watch \
  wget \
  wxwidgets \
  wxwidgets@3.2 \
  xcodes \
  xerces-c \
  xq \
  yq \
  zsync

brew install --cask \
  ableton-live-suite \
  adobe-acrobat-reader \
  android-platform-tools \
  audacity \
  blender \
  db-browser-for-sqlite \
  dbeaver-community \
  docker \
  eclipse-ide \
  firefox \
  github \
  google-chrome \
  google-driv \
  headlamp \
  lmms \
  mysqlworkbench \
  openscad \
  podman-desktop \
  pgadmin4 \
  postgres-unofficial \
  processing \
  quarto \
  reaper \
  rstudio \
  session-manager-plugin \
  steam \
  sublime-text \
  tigervnc-viewer \
  utm \
  vagrant \
  virtualbox \
  visual-studio-code \
  vlc \
  xquartz

# Python stuff
#pip3 install --user bitstring uritools nose tornado boto3 lz4tools genson pypi matplotlib numpy py-gnuplot debugpy
#   guitar-pro \
#sudo scutil --set ComputerName foobar

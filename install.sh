#!/bin/bash

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

mkdir -p ${HOME}/development/
mkdir -p ${HOME}/.ssh && chmod 700 ${HOME}/.ssh

SHELL_PREFERRED=bash
export HOMEBREW_NO_ASK=1

# export HOMEBREW=/opt/homebrew
# mkdir -p ${HOMEBREW}
# git clone --depth=1 https://github.com/Homebrew/brew "${HOMEBREW}"

install_xcode() {
  sudo bash -c "
    #softwareupdate -i -a
    #softwareupdate --install-rosetta
    xcode-select --install
    xcodebuild -license accept
  "
}

set_shell() {
  [[ "${SHELL_PREFERRED}" == "bash" ]] || return 0

  local brew_bash
  brew_bash="$(brew --prefix 2>/dev/null)/bin/bash"
  if [[ ! -x "${brew_bash}" ]]; then
    echo "Homebrew bash not found, leaving login shell unchanged"
    return 0
  fi

  # chsh only accepts shells listed in /etc/shells
  if ! grep -qxF "${brew_bash}" /etc/shells; then
    echo "${brew_bash}" | sudo tee -a /etc/shells > /dev/null
  fi

  if [[ "$(dscl . -read ~/ UserShell | awk '{print $2}')" != "${brew_bash}" ]]; then
    chsh -s "${brew_bash}"
  fi
}

install() {
  echo "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ${HOME}/.bash_profile
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew install cask
}

update() {
  brew update
  brew upgrade
  brew upgrade --cask
  brew cleanup
}

work() {
  brew install act \
    actionlint \
    amazon-ecs-cli \
    ansible \
    autoconf \
    aws-shell \
    awscli \
    awslogs \
    bash \
    bash-completion@2 \
    cask \
    cmake \
    colordiff \
    coreutils \
    couchdb \
    cspice \
    curl \
    diffoci \
    direnv \
    dive \
    docker \
    docker-squash \
    docutils \
    dos2unix \
    duckdb \
    emscripten \
    espeak-ng \
    gawk \
    gh \
    git \
    gitlab-ci-local \
    gnu-getopt \
    gnu-sed \
    gnuplot \
    go \
    go-md2man \
    go-task \
    gradle \
    graphviz \
    grep \
    hiredis \
    htop \
    iftop \
    ipython \
    jansson \
    javacc \
    jq \
    jupyter-r \
    jupytext \
    k3sup \
    derailed/k9s/k9s \
    kionsoftware/tap/kion-cli \
    kind \
    kompose \
    kubectl \
    kubectx \
    kustomize \
    lazydocker \
    libfido2 \
    links \
    lynx \
    make \
    maven \
    memcached \
    midnight-commander \
    minikube \
    nano \
    netcat \
    nmap \
    node@20 \
    nvm \
    octave \
    openconnect \
    openjdk@21 \
    openmotif \
    openvpn \
    p11-kit \
    p7zip \
    parallel \
    peco \
    perl \
    pidof \
    pipx \
    podman-compose \
    poppler \
    postgresql \
    pyqt \
    pyqt@5 \
    python \
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
    skopeo \
    socket_vmnet \
    speedtest-cli \
    swig \
    tcpdump \
    terragrunt \
    tig \
    tmux \
    trivy \
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
    brave-browser \
    dbeaver-community \
    eclipse-ide \
    github \
    headlamp \
    inkscape \
    lens \
    pgadmin4 \
    podman-desktop \
    postgres-app \
    postgres-unofficial \
    processing \
    sublime-text \
    tigervnc \
    tigervnc-viewer \
    utm \
    visual-studio-code \
    vlc
}

home() {
  work

  brew install --cask \
    ableton-live-suite \
    adobe-acrobat-reader \
    android-platform-tools \
    arduino \
    audacity \
    blender \
    firefox \
    fluid-synth \
    freecad \
    google-chrome \
    google-drive \
    lilypond \
    lmms \
    openscad \
    reaper \
    steam \
    surge-xt
}

sudo_needed() {
  sudo brew install docker-desktop \
    kiro-cli \
    launchctl \
    mysql \
    quarto \
    r-app \
    rstudio \
    session-manager-plugin \
    vagrant \
    virtualbox \
    xquartz
}

if [[ $(command -v brew) == "" ]]; then
  install
fi

echo "Select action:"
echo "  1) install_xcode"
echo "  2) update"
echo "  3) work"
echo "  4) home"
read -r -p "Choice [1/2/3/4]: " choice

case "${choice}" in
  1) install_xcode ;;
  2) update ;;
  3) work ;;
  4)
    read -r -p "Are you sure you want to install home packages? [y/N]: " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
      home
    else
      echo "Aborted."
      exit 0
    fi
    ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

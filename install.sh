#!/bin/bash

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

mkdir -p ${HOME}/development/
mkdir -p ${HOME}/.ssh && chmod 700 ${HOME}/.ssh

install_xcode() {
  sudo bash -c "
    #softwareupdate -i -a
    #softwareupdate --install-rosetta
    xcode-select --install
    xcodebuild -license accept
    chsh -s /bin/bash
  "
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
    k9s \
    kionsoftware/tap/kion-cli \
    kind \
    kompose \
    kubectl \
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
    openmotif \
    openvpn \
    p7zip \
    parallel \
    peco \
    perl \
    pidof \
    pipx \
    podman-compose \
    poppler \
    postgresql@17 \
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

# adobe-acrobat-reader will be installed by the entity managing device 
  brew install --cask \
    brave-browser \
    dbeaver-community \
    eclipse-ide \
    github \
    headlamp \
    inkscape \
    kiro-cli \
    lens \
    pgadmin4 \
    podman-desktop \
    postgres-app \
    postgres-unofficial \
    processing \
    quarto \
    r-app \
    rstudio \
    session-manager-plugin \
    sublime-text \
    tigervnc \
    tigervnc-viewer \
    utm \
    vagrant \
    virtualbox \
    visual-studio-code \
    vlc \
    xquartz
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
    docker \
    firefox \
    fluid-synth \
    freecad \
    google-chrome \
    google-drive \
    lmms \
    openscad \
    reaper \
    steam \
    surge-xt
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

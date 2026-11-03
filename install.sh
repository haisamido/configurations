#!/bin/bash

# Official location, so formulae install from bottles. Same as brew shellenv sets
HOMEBREW_PREFIX=/opt/homebrew

# Don't stop to ask "Do you want to proceed with the installation? [y/n]"
export HOMEBREW_NO_ASK=1

# Apple Silicon only (Intel's /usr/local is shared with non-Homebrew software)
if [[ "$(uname -m)" != arm64 ]]; then
  echo "This script supports Apple Silicon Macs only"
  exit 1
fi

# Use this brew even if another one is first on PATH
if [[ ! -x "${HOMEBREW_PREFIX}/bin/brew" ]]; then
  echo "Homebrew isn't installed in ${HOMEBREW_PREFIX}. Install it first (README, step 3)"
  exit 1
fi

eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"

# Tap to click (takes effect after logging out and back in)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Keep the Mac awake until this script exits
caffeinate -is -w $$ &

# Prepare development and ssh area
mkdir -p "${HOME}/development/"
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"

# Check the admin group first so non-admins never hit a sudo prompt (or a logged failure),
# then confirm sudo actually works
if ! dseditgroup -o checkmember -m "${USER}" admin > /dev/null 2>&1; then
  HAS_ADMIN=false
  echo "${USER} is not an administrator, skipping steps that need sudo"
elif sudo -v; then
  HAS_ADMIN=true
  # Keep sudo cached while the script runs, so the password is asked only once
  while kill -0 $$ 2>/dev/null; do sudo -n true; sleep 60; done 2>/dev/null &
else
  echo "sudo failed (wrong password, cancelled, or admin expired). Re-run to try again"
  exit 1
fi

# Homebrew needs the Command Line Tools
if ! xcode-select -p > /dev/null 2>&1; then
  echo "Command Line Tools not found. Starting the installer, re-run this script when it finishes."
  xcode-select --install
  exit 1
fi

# brew won't run as root, so every file in the prefix must be ours. Scanning the whole
# prefix takes a couple of seconds, so it runs only before brew changes anything
check_homebrew_owner() {
  local not_owned
  not_owned="$(find "${HOMEBREW_PREFIX}" ! -user "${USER}" -print -quit 2>/dev/null)"
  if [[ -n "${not_owned}" ]]; then
    echo "${HOMEBREW_PREFIX} isn't fully owned by ${USER} (e.g. ${not_owned})."
    echo "With admin rights (yours or IT's), fix it with:"
    echo "  sudo chown -R ${USER}:admin ${HOMEBREW_PREFIX}"
    exit 1
  fi
}

update() {
  check_homebrew_owner
  brew update
  brew upgrade --formula
  brew cleanup
}

work_formulae() {
  brew install act \
    actionlint \
    amazon-ecs-cli \
    ansible \
    autoconf \
    aws-c-auth \
    aws-c-cal \
    aws-c-common \
    aws-c-compression \
    aws-c-event-stream \
    aws-c-http \
    aws-c-io \
    aws-c-mqtt \
    aws-c-s3 \
    aws-c-sdkutils \
    aws-checksums \
    aws-sam-cli \
    aws-shell \
    awscli \
    awslogs \
    bash \
    bash-completion@2 \
    cask \
    cmake \
    colordiff \
    coreutils \
    cosign \
    couchdb \
    cppcheck \
    cspice \
    curl \
    diffoci \
    direnv \
    dive \
    docker-compose \
    docker \
    docker-squash \
    docutils \
    dos2unix \
    duckdb \
    emscripten \
    espeak-ng \
    gawk \
    gcc \
    gh \
    git \
    gitlab-ci-local \
    gnu-getopt \
    gnu-sed \
    gnupg \
    gnuplot \
    go \
    go-md2man \
    go-task \
    gradle \
    graphviz \
    grep \
    helm \
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
    nvm \
    octave \
    openjdk@21 \
    openmotif \
    openvpn \
    p11-kit \
    p7zip \
    parallel \
    peco \
    perl \
    pidof \
    pigz \
    pipx \
    podman \
    podman-compose \
    poppler \
    postgresql \
    pyqt \
    pyqt@5 \
    python \
    python-matplotlib \
    qemu \
    qt \
    r \
    rclone \
    redis \
    rpm2cpio \
    rsync \
    ruby \
    rust \
    s3cmd \
    scrcpy \
    shellcheck \
    skopeo \
    speedtest-cli \
    swig \
    tcpdump \
    hashicorp/tap/terraform \
    terragrunt \
    tig \
    tmux \
    trivy \
    uv \
    watch \
    wget \
    wxwidgets \
    wxwidgets@3.2 \
    xcodes \
    xerces-c \
    xq \
    yq \
    zstd \
    zsync
}

work_casks() {
  brew install --cask \
    brave-browser \
    dbeaver-community \
    docker-desktop \
    eclipse-ide \
    github \
    headlamp \
    inkscape \
    kiro-cli \
    lens \
    pgadmin4 \
    podman-desktop \
    postgres-app \
    processing \
    quarto \
    r-app \
    rstudio \
    session-manager-plugin \
    sublime-text \
    tigervnc \
    utm \
    vagrant \
    virtualbox \
    visual-studio-code \
    vlc \
    xquartz
}

# Casks go to /Applications, which only admins can write to
work() {
  check_homebrew_owner
  work_formulae
  if [[ "${HAS_ADMIN}" == true ]]; then
    work_casks
  else
    echo "Skipping casks: installing into /Applications needs admin"
  fi
}

home() {
  work

  brew install fluid-synth \
    lilypond

  brew install --cask \
    ableton-live-suite \
    android-platform-tools \
    arduino-ide \
    audacity \
    blender \
    firefox \
    freecad \
    google-chrome \
    lmms \
    openscad \
    reaper \
    steam

  # These use .pkg installers, which need admin rights
  if [[ "${HAS_ADMIN}" == true ]]; then
    brew install --cask \
      adobe-acrobat-reader \
      google-drive \
      surge-xt
  fi
}

echo "Select action:"
echo "  1) update"
echo "  2) work"
echo "  3) home"
read -r -p "Choice [1/2/3]: " choice

case "${choice}" in
  1) update ;;
  2) work ;;
  3)
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

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
  echo "Homebrew isn't installed in ${HOMEBREW_PREFIX}. Install it first (README, step 1)"
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

# Checking the admin group doesn't invoke sudo, so it never prompts or logs a failed attempt
if dseditgroup -o checkmember -m "${USER}" admin > /dev/null 2>&1; then
  HAS_ADMIN=true
else
  HAS_ADMIN=false
  echo "${USER} is not an administrator, apps (casks) will be skipped"
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

update_formulae() {
  check_homebrew_owner
  brew update
  brew upgrade --formula
  brew cleanup
}

work_formulae() {
  brew install act \
    actionlint \
    age \
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
    fd \
    fzf \
    gawk \
    gcc \
    gh \
    git \
    git-delta \
    gitlab-ci-local \
    gnu-getopt \
    gnu-sed \
    gnu-tar \
    gnupg \
    gnuplot \
    go \
    go-md2man \
    go-task \
    gradle \
    graphviz \
    grep \
    grype \
    hadolint \
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
    kubeconform \
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
    pandoc \
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
    pre-commit \
    pyqt \
    pyqt@5 \
    python \
    python-matplotlib \
    qemu \
    qt \
    r \
    rclone \
    redis \
    ripgrep \
    rpm2cpio \
    rsync \
    ruby \
    rust \
    s3cmd \
    scrcpy \
    shellcheck \
    shfmt \
    skopeo \
    sops \
    speedtest-cli \
    stern \
    swig \
    syft \
    tcpdump \
    hashicorp/tap/terraform \
    terraform-docs \
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
    yamllint \
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

# Casks go to /Applications, which only admins can write to, and .pkg casks call sudo.
# Ask for the password (or PIN) only here, once per run, and keep it cached so brew's own
# sudo calls don't stop and ask again
can_install_casks() {
  if [[ "${HAS_ADMIN}" != true ]]; then
    echo "Skipping casks: installing into /Applications needs admin"
    return 1
  fi
  # Already asked this run: don't ask again
  case "${SUDO_READY}" in
    true) return 0 ;;
    false) echo "Skipping casks"; return 1 ;;
  esac
  echo "Installing apps (casks) next. Some use .pkg installers that need sudo, so enter your"
  echo "password or smart-card PIN once. It stays cached until this script finishes."
  if ! sudo -v; then
    SUDO_READY=false
    echo "sudo failed (wrong password, cancelled, or admin expired). Skipping casks"
    return 1
  fi
  SUDO_READY=true
  while kill -0 $$ 2>/dev/null; do sudo -n true; sleep 60; done > /dev/null 2>&1 &
}

# Apps that update themselves (VS Code, browsers) are left to their own updaters
update_casks() {
  check_homebrew_owner
  can_install_casks || return 0
  brew update
  brew upgrade --cask
  brew cleanup
}

# Both together, with the ownership scan and brew update run once
update() {
  check_homebrew_owner
  brew update
  brew upgrade --formula
  can_install_casks && brew upgrade --cask
  brew cleanup
}

work() {
  check_homebrew_owner
  work_formulae
  can_install_casks && work_casks
}

home() {
  work

  brew install fluid-synth \
    lilypond

  can_install_casks || return 0

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

  # These use .pkg installers
  brew install --cask \
    adobe-acrobat-reader \
    google-drive \
    surge-xt
}

echo "Select action:"
echo "  1) Install work (formulae, then casks)"
echo "  2) Install work formulae only"
echo "  3) Install work casks only"
echo "  4) Install home (formulae, then casks)"
echo "  5) update (formulae, then casks)"
echo "  6) update formulae only"
echo "  7) update casks only"
read -r -p "Choice [1/2/3/4/5/6/7]: " choice

case "${choice}" in
  1) echo; echo "Selected 1) Install work (formulae, then casks)" ;;
  2) echo; echo "Selected 2) Install work formulae only" ;;
  3) echo; echo "Selected 3) Install work casks only" ;;
  4) echo; echo "Selected 4) Install home (formulae, then casks)" ;;
  5) echo; echo "Selected 5) update (formulae, then casks)" ;;
  6) echo; echo "Selected 6) update formulae only" ;;
  7) echo; echo "Selected 7) update casks only" ;;
esac

case "${choice}" in
  1) work ;;
  2) check_homebrew_owner; work_formulae ;;
  3) check_homebrew_owner; can_install_casks && work_casks ;;
  4)
    read -r -p "Are you sure you want to install home packages? [y/N]: " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
      home
    else
      echo "Aborted."
      exit 0
    fi
    ;;
  5) update ;;
  6) update_formulae ;;
  7) update_casks ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

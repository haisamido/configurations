#!/bin/bash

SHELL_PREFERRED=bash

# Membership in the admin group is what grants sudo on macOS. Checking it doesn't
# invoke sudo, so it won't prompt for a password or log a failed attempt
if dseditgroup -o checkmember -m "${USER}" admin > /dev/null 2>&1; then
  HAS_ADMIN=true
else
  HAS_ADMIN=false
  echo "${USER} is not an administrator, skipping steps that need sudo"
fi

# Homebrew and every source build need the Command Line Tools
if ! xcode-select -p > /dev/null 2>&1; then
  echo "Command Line Tools not found. Starting the installer, re-run this script when it finishes."
  xcode-select --install
  exit 1
fi

# Enable tap to click on the trackpad (off by default). Takes effect after logging out and back in
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Keep the Mac awake until this script exits, so long source builds aren't interrupted by sleep
caffeinate -is -w $$ &

# Prepare development and ssh area
mkdir -p "${HOME}/development/"
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"

# Homebrew configs
# Homebrew 7 asks "Do you want to proceed with the installation? [y/n]" whenever an install
# pulls in dependencies. Turn that off so long unattended runs don't stall waiting for input
export HOMEBREW_NO_ASK=1

install_xcode() {
  if [[ "${HAS_ADMIN}" != true ]]; then
    echo "install_xcode needs sudo, skipping"
    return 0
  fi
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
    if [[ "${HAS_ADMIN}" != true ]]; then
      echo "Adding ${brew_bash} to /etc/shells needs sudo, leaving login shell unchanged"
      return 0
    fi
    echo "${brew_bash}" | sudo tee -a /etc/shells > /dev/null
  fi

  if [[ "$(dscl . -read ~/ UserShell | awk '{print $2}')" != "${brew_bash}" ]]; then
    chsh -s "${brew_bash}"
  fi
}

# /opt/homebrew is the official location and gets prebuilt bottles, but needs admin rights.
# ~/.local/homebrew needs no admin rights, but many formulae build from source there
install_homebrew() {
  # The official installer uses /opt/homebrew on Apple Silicon and /usr/local on Intel
  local system_prefix=/opt/homebrew
  [[ "$(uname -m)" == x86_64 ]] && system_prefix=/usr/local

  local prefix="${HOME}/.local/homebrew" choice
  if [[ "${HAS_ADMIN}" == true ]]; then
    read -r -p "Install Homebrew in 1) ${system_prefix} (needs sudo) or 2) ~/.local/homebrew? [1/2]: " choice
    [[ "${choice}" == 1 ]] && prefix="${system_prefix}"
  fi
  echo "Installing Homebrew into ${prefix}"

  # Lines added to ~/.bash_profile (if missing) and applied to this run
  local profile_lines=("eval \"\$(${prefix}/bin/brew shellenv)\"")
  if [[ "${prefix}" == "${system_prefix}" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    mkdir -p "${prefix}" "${HOME}/Applications-user"
    curl -fsSL https://github.com/Homebrew/brew/tarball/HEAD | tar xz --strip-components=1 -C "${prefix}"
    # Casks default to /Applications, which needs admin rights
    profile_lines+=("export HOMEBREW_CASK_OPTS=\"--appdir=\${HOME}/Applications-user\"")
  fi

  if [[ ! -x "${prefix}/bin/brew" ]]; then
    echo "Homebrew installation into ${prefix} failed"
    exit 1
  fi

  local line
  for line in "${profile_lines[@]}"; do
    grep -qxF "${line}" "${HOME}/.bash_profile" 2>/dev/null || echo "${line}" >> "${HOME}/.bash_profile"
    eval "${line}"
  done

  # The tarball has no git history; this turns it into a normal, updatable install
  [[ "${prefix}" == "${system_prefix}" ]] || brew update --force --quiet
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
    pipx \
    podman-compose \
    poppler \
    postgresql \
    python \
    python-matplotlib \
    redis \
    rpm2cpio \
    rsync \
    ruby \
    rust \
    s3cmd \
    scrcpy \
    skopeo \
    speedtest-cli \
    swig \
    tcpdump \
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
    processing \
    sublime-text \
    tigervnc \
    utm \
    visual-studio-code \
    vlc

  if [[ "${HAS_ADMIN}" == true ]]; then
    sudo_needed
  fi

#  set_shell
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

# Packages that need admin rights to install: their .pkg installers or system extensions
# write to /Applications, /Library, /opt or /usr/local. Run only when HAS_ADMIN=true.
# No sudo here: Homebrew refuses to run as root and asks for a password itself when needed
sudo_needed() {
  brew install docker-desktop \
    kiro-cli \
    quarto \
    r-app \
    rstudio \
    session-manager-plugin \
    vagrant \
    virtualbox \
    xquartz
}

# Load an existing Homebrew even if this shell doesn't have it on PATH, so it isn't reinstalled
for p in "${HOME}/.local/homebrew" /opt/homebrew /usr/local; do
  [[ -x "${p}/bin/brew" ]] && eval "$("${p}/bin/brew" shellenv)" && break
done
if ! command -v brew > /dev/null; then
  install_homebrew
fi

# Casks default to /Applications, which needs admin rights. Don't rely on the profile having this
if [[ "$(brew --prefix)" == "${HOME}/.local/homebrew" && -z "${HOMEBREW_CASK_OPTS}" ]]; then
  export HOMEBREW_CASK_OPTS="--appdir=${HOME}/Applications-user"
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

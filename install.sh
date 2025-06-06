
sudo bash -c "
  #softwareupdate -i -a
  xcode-select --install
  xcodebuild -license accept
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

brew install amazon-ecs-cli \
    ansible \
    aom \
    autoconf \
    aws-shell \
    awscli \
    awslogs \
    bash \
    bash-completion \
    cask \
    cmake \
    colordiff \
    coreutils \
    couchdb \
    cspice \
    curl \
    direnv \
    dive \
    docker-squash \
    docutils \
    dos2unix \
    duckdb \
    emacs \
    ffmpeg \
    fig2dev \
    fluid-synth \
    flux \
    gawk \
    gcc \
    gd \
    gettext \
    gh \
    ghostscript \
    git \
    gitlab-ci-local \
    glib \
    gnu-sed \
    gnupg \
    gnuplot \
    gnutls \
    go \
    go-md2man \
    go-task \
    gpgme \
    gradle \
    graphicsmagick \
    graphviz \
    grep \
    gts \
    harfbuzz \
    hdf5 \
    htop \
    iftop \
    imagemagick \
    javacc \
    jpeg-xl \
    jq \
    jupyter-r \
    jupyterlab \
    k3sup \
    k9s \
    kind \
    kompose \
    kubectx \
    kubernetes-cli \
    kustomize \
    lazydocker \
    libass \
    libavif \
    libfido2 \
    libheif \
    librsvg \
    links \
    lynx \
    lz4 \
    make \
    maven \
    midnight-commander \
    minikube \
    mysql \
    nano \
    netcat \
    netpbm \
    nmap \
    node@20 \
    nvm \
    octave \
    open-mpi \
    openconnect \
    openvpn \
    p7zip \
    pandoc \
    parallel \
    peco \
    pidof \
    pipx \
    pmix \
    podman \
    podman-compose \
    poppler \
    postgresql@15 \
    pulumi \
    pyqt \
    pyqt@5 \
    python-matplotlib \
    python@3.12 \
    qemu \
    qscintilla2 \
    qt \
    r \
    rpm2cpio \
    rsync \
    ruby \
    rust \
    s3cmd \
    scrcpy \
    socket_vmnet \
    speedtest-cli \
    suite-sparse \
    sundials \
    tcpdump \
    terraform \
    terragrunt \
    tig \
    tmux \
    tree \
    watch \
    wget \
    xq \
    yq

brew install --cask adobe-acrobat-reader \
    android-platform-tools \
    audacity \
    blender \
    db-browser-for-sqlite \
    dbeaver-community \
    firefox \
    github \
    google-chrome \
    headlamp \
    mysqlworkbench \
    openscad \
    podman-desktop \
    postgres-unofficial \
    processing \
    quarto \
    rstudio \
    session-manager-plugin \
    sublime-text \
    tigervnc-viewer \
    utm \
    vagrant \
    virtualbox \
    visual-studio-code \
    vlc \
    xquartz

brew install --cask docker

# Python stuff
#pip3 install --user bitstring uritools nose tornado boto3 lz4tools genson pypi matplotlib numpy py-gnuplot debugpy

#sudo scutil --set ComputerName foobar

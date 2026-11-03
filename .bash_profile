# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:${HOME}/.docker/bin"
# End of Docker Desktop section.

if [ -f /etc/bashrc ]; then
. /etc/bashrc
fi

export HISTSIZE=
export HISTFILESIZE=
export HISTTIMEFORMAT="| %FT%T%z | "

__prompt_cmd() {
  local branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  local git_info=""
  if [ -n "$branch" ]; then
    local hash=$(git rev-parse --short HEAD 2>/dev/null)
    git_info="\[\e[91m\](${branch}:\[\e[90m\]${hash}\[\e[91m\])"
  fi
  PS1="\[\e[33m\]\u\[\e[37m\]@\[\e[36m\]\h\[\e[32m\]:\w ${git_info}\[\e[00m\]$ "
}
PROMPT_COMMAND=__prompt_cmd

# Homebrew (/opt/homebrew, owned by this account, so brew never needs sudo)
export HOMEBREW=/opt/homebrew
export HOMEBREW_BIN=${HOMEBREW}/bin
export HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_AUTOREMOVE=1
export HOMEBREW_NO_ASK=1

# INSTALLS
export GNU_INSTALL=${HOMEBREW_BIN}
export GO_INSTALL=${HOME}/go/bin

eval "$("${HOMEBREW_BIN}/brew" shellenv)"
export PATH=${HOME}/.local/bin:${GO_INSTALL}:${PATH}

# GNU tools, only where installed
for t in make date grep head sed readlink; do
  [[ -x "${GNU_INSTALL}/g${t}" ]] && alias "${t}=${GNU_INSTALL}/g${t}"
done

# Tab completion (bash-completion@2; also loads make, task, kubectl, gh)
[[ -r "${HOMEBREW}/etc/profile.d/bash_completion.sh" ]] && . "${HOMEBREW}/etc/profile.d/bash_completion.sh"

# fzf: Ctrl-R fuzzy history search, Ctrl-T file picker, Alt-C cd
[[ $- == *i* ]] && command -v fzf > /dev/null && eval "$(fzf --bash)"

# Point docker, act, lazydocker and dive at Podman's Docker-compatible socket
if command -v podman > /dev/null; then
  export KIND_EXPERIMENTAL_PROVIDER=podman
  podman_sock="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
  [[ -n "${podman_sock}" ]] && export DOCKER_HOST="unix://${podman_sock}"
  unset podman_sock
fi

my_ip=$(ifconfig|grep 'inet '|grep -v '127.0.0.1'| head -1|awk '{print $2}')

alias brewup='brew update; brew upgrade; brew cleanup; brew doctor'
alias ls='ls -GFh'
alias pivssh='ssh -A -o PKCS11Provider=/usr/lib/ssh-keychain.dylib'
alias clone='git clone --recurse-submodules -j8'

export JAVA_HOME="${HOMEBREW}/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"

export NVM_DIR="$HOME/.nvm"
[ -s "${HOMEBREW}/opt/nvm/nvm.sh" ] && \. "${HOMEBREW}/opt/nvm/nvm.sh"
[ -s "${HOMEBREW}/etc/bash_completion.d/nvm" ] && \. "${HOMEBREW}/etc/bash_completion.d/nvm"

# Personal and work settings that don't belong in a public repo: project paths,
# AWS profiles, git identities. Keep them in ~/.bash_profile.local
[[ -r "${HOME}/.bash_profile.local" ]] && . "${HOME}/.bash_profile.local"

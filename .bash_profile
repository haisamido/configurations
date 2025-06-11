
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

#source /Users/hido/.dotfiles/.bashrc
source ~/perl5/perlbrew/etc/bashrc
#source ~/.profile

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
export PS1="\u@\h \[\e[32m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]$ "
complete -W "\`grep -oP '^[a-zA-Z0-9_.%\-]+:([^=]|$)' ?akefile | sed 's/[^a-zA-Z0-9_.%\-]*$//'\`" make

export DOCKER_DEFAULT_PLATFORM=linux/amd64

export TAAS_PATH=${HOME}/development/SSMO/SSMO-DAT
export SSMO_MISC_PATH=${HOME}/development/SSMO/SSMO-Misc
export SC_PATH=${HOME}/development/SSMO/Spacecraft
export SPACECRAFT_PATH=$SC_PATH
export DASH_PATH=${HOME}/development/SSMO/SSMO-Dash

export ENVIRO=dev
export CONTEXT=development

export HISTSIZE=
export HISTFILESIZE=

my_ip=$(ifconfig|grep 'inet '|grep -v '127.0.0.1'| head -1|awk '{print $2}')

# INSTALLS
GNU_INSTALL=/opt/homebrew/bin
GO_INSTALL=${HOME}/go/bin

export PATH=/usr/local/bin:${GO_INSTALL}:$GNU_INSTALL:$PATH

eval "$($GNU_INSTALL/brew shellenv)"

alias make="$GNU_INSTALL/gmake"
alias date="$GNU_INSTALL/gdate"
alias grep="$GNU_INSTALL/ggrep"
alias head="$GNU_INSTALL/ghead"
alias sed="$GNU_INSTALL/gsed"
alias readlink="$GNU_INSTALL/greadlink"

alias brewup='brew update; brew upgrade; brew cleanup; brew doctor'

alias ls='ls -GFh'

alias pivssh='ssh -A -o PKCS11Provider=/usr/lib/ssh-keychain.dylib'
alias clone='git clone --recurse-submodules -j8'


export JAVA_HOME=/opt/homebrew/opt/openjdk\@21/libexec/openjdk.jdk/Contents/Home

#eval "$(direnv hook bash)"

getent() {
  [ "$1" == "hosts" ] && shift
  for x
  do
    echo $x $(dscacheutil -q host -a name $x | awk '/^ip_address/{print $NF}')
  done
}

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/etc/bash_completion.d/nvm"

# source ${HOME}/.venv/bin/activate

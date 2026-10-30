# configurations

## Quick start

On a Mac, with or without admin rights, run:

```bash
./install.sh
```

It works out whether your account is an administrator, then:

1. Checks for the Command Line Tools and starts Apple's installer if they're missing.
2. Installs Homebrew if it isn't already installed. Admins choose
   `/opt/homebrew` or `~/.local/homebrew`; everyone else gets `~/.local/homebrew`.
3. Shows a menu:

   | Choice | Does |
   |---|---|
   | 1) `install_xcode` | Accepts the Xcode license (needs sudo) |
   | 2) `update` | Updates and upgrades all Homebrew packages |
   | 3) `work` | Installs the work packages, plus `sudo_needed()` for admins |
   | 4) `home` | Everything in `work`, plus the home apps (asks to confirm). The three that need admin rights install only for admins |

The script keeps the Mac awake until it finishes, so long installs aren't
interrupted. You can run it again safely: Homebrew skips packages that are
already installed.

The rest of this README explains how the no-admin setup works and how to fix
problems you might run into.

## macOS without admin rights

These steps set up a Mac where `sudo` exists but your account isn't an
administrator (you aren't in the `admin` group or in sudoers). Everything
installs into your home directory:

| Path | Contents |
|---|---|
| `~/.local/homebrew` | Homebrew and its formulae |
| `~/Applications-user` | GUI apps installed with `brew install --cask` |
| `~/.local/bin` | Standalone binaries (for example podman and its helpers) |

Don't run `sudo` for any step. Homebrew refuses to run as root, and a failed
`sudo` attempt on a managed Mac is logged and may be reported.

### 1. Command Line Tools

Homebrew needs Apple's Command Line Tools (compilers, `git`, `make`). On the
managed Mac this setup was written for, IT had already installed them, so this
step may not be needed on yours either. `install.sh` checks for them before
doing anything else. To check yourself:

```bash
xcode-select -p
```

If that prints an error, run `xcode-select --install`. If the installer asks
for an administrator password, ask IT to install the Command Line Tools for you.

### 2. Install Homebrew into your home directory

`install.sh` does this for you. These are the same steps, if you want to do
them by hand.

The official installer wants `/opt/homebrew`, which needs admin rights.
Unpack Homebrew into your home directory instead:

```bash
export HOMEBREW="${HOME}/.local/homebrew"
mkdir -p "${HOMEBREW}"
curl -L https://github.com/Homebrew/brew/tarball/HEAD | tar xz --strip-components=1 -C "${HOMEBREW}"
eval "$("${HOMEBREW}/bin/brew" shellenv)"
brew update --force --quiet
```

If you'd rather use `git`, this works instead of the `curl` line:

```bash
git clone --depth=1 https://github.com/Homebrew/brew "${HOMEBREW}"
```

Homebrew doesn't support installing to a custom location, so expect the following:

- **Many formulae build from source.** Prebuilt bottles are made for
  `/opt/homebrew`, and those with that path compiled in can't be used anywhere
  else. Large builds (llvm, gcc, node, python, mysql, qt) can take an hour or
  more, and they rebuild again on every upgrade. `brew doctor` will warn about
  the location; you can ignore that warning.
- **Casks that ship a `.pkg` installer fail.** A `.pkg` writes to system
  locations and needs admin rights. Casks that contain only an `.app` work fine.
  The packages that need admin are listed in `sudo_needed()` in
  [install.sh](install.sh), which runs only when your account is an
  administrator.

### 3. Shell profile

Add the following to `~/.bash_profile`. Each block is explained below.

```bash
# --- Homebrew in $HOME ---------------------------------------------------
export HOMEBREW="${HOME}/.local/homebrew"
eval "$("${HOMEBREW}/bin/brew" shellenv)"
export HOMEBREW_CASK_OPTS="--appdir=${HOME}/Applications-user"
export HOMEBREW_NO_ASK=1        # don't stop for confirmation during long installs

export PATH="${HOME}/.local/bin:${PATH}"

# --- GNU tools, only where installed --------------------------------------
for t in make date grep head sed readlink; do
  [[ -x "${HOMEBREW}/bin/g${t}" ]] && alias "${t}=${HOMEBREW}/bin/g${t}"
done

# --- Tab completion (bash-completion@2; also loads task, kubectl, gh) -----
[[ -r "${HOMEBREW}/etc/profile.d/bash_completion.sh" ]] && . "${HOMEBREW}/etc/profile.d/bash_completion.sh"

# --- Point docker, act, lazydocker and dive at Podman's Docker-compatible socket
if command -v podman > /dev/null; then
  podman_sock="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
  [[ -n "${podman_sock}" ]] && export DOCKER_HOST="unix://${podman_sock}"
  unset podman_sock
fi
export KIND_EXPERIMENTAL_PROVIDER=podman

# --- Paths derived from the brew prefix, not hard-coded /opt/homebrew -----
export JAVA_HOME="${HOMEBREW}/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
```

What each block does:

- **Homebrew.** `shellenv` puts `~/.local/homebrew/bin` on `PATH`, and
  `HOMEBREW_CASK_OPTS` sends cask apps to `~/Applications-user` instead of
  `/Applications`, which needs admin rights.
- **GNU tools.** The aliases are set only for tools that are installed. An alias
  to a missing `gsed` would break every command that runs `sed`, including the
  prompt.
- **Completion.** This is the `bash-completion@2` loader. It also loads
  completions that formulae such as `go-task`, `kubectl` and `gh` install into
  `etc/bash_completion.d`. It needs bash 4.2 or newer. Under macOS's own bash
  3.2 it silently does nothing, so you only get completion in Homebrew's bash
  (`~/.local/homebrew/bin/bash`). You can't make that your login shell without
  admin rights, because `chsh` only accepts shells listed in `/etc/shells`,
  which is owned by root.
- **`DOCKER_HOST`.** Without admin rights, `podman-mac-helper` can't create
  `/var/run/docker.sock`. This points the `docker` CLI and Docker API clients
  (`act`, `lazydocker`, `dive`) at Podman's socket instead. The socket lives in
  a temporary folder whose path can change, so it's looked up each time a shell
  starts. It's only set when a Podman machine exists: an empty
  `DOCKER_HOST="unix://"` would break `docker`. It needs `export` so that
  programs you start can see it. This belongs in your profile, not in
  `install.sh`, because a variable set in a script is gone when the script exits.
- **Hard-coded paths.** Replace anything that hard-codes `/opt/homebrew/...`
  with `${HOMEBREW}/...`. This includes `JAVA_HOME`, `nvm.sh` and earlier
  `brew shellenv` lines.

Things to keep out of `~/.bash_profile`:

- **Anything that prints.** `echo` lines and commands whose errors reach the
  terminal show up in every `bash -lc` call, which confuses VS Code's
  environment lookup and breaks `scp` and `rsync` into this Mac.
- **Slow or network commands**, such as `aws s3 ls`. They run in every new
  shell, including the ones VS Code and scripts start. If you want them, run
  them only in interactive shells (`[[ $- == *i* ]]`), send all of their output
  to a file (`> file 2>&1`), and expect a `[1] 12345` job message for each one
  run in the background.
- **Backslashes inside double quotes.** `"…/Visual\ Studio\ Code.app/…"` keeps
  the backslashes as part of the path, so the `PATH` entry never matches.
  Inside double quotes, the space needs no escaping.
- **`$PWD#/home/$USER` in the prompt.** Home folders are under `/Users` on
  macOS, so it never shortens anything. Use `\w` instead.

Typing `bash` on its own starts a non-login shell, which reads `~/.bashrc`
rather than `~/.bash_profile`, so it gets your exported variables but not your
aliases or completion. If that matters to you, put aliases and completion in
`~/.bashrc` and add `[[ -r ~/.bashrc ]] && . ~/.bashrc` to `~/.bash_profile`.

### 4. Install packages

```bash
./install.sh     # choose "work"
```

`install.sh` keeps the Mac awake with `caffeinate` until it exits, so long
source builds aren't cut short by sleep. If a run stops partway through
(Ctrl-C, a closed terminal, a `sudo` prompt), the interrupted formula starts
its build again from scratch next time.

To see what's installed:

```bash
brew leaves --installed-on-request    # formulae you asked for
brew list --cask
```

To save that list to [brew_installs.txt](brew_installs.txt), for example to
compare with the package lists in `install.sh`:

```bash
f=brew_installs.txt
echo "# formulae" > "$f"
brew leaves --installed-on-request | sort >> "$f"
printf '\n# casks\n' >> "$f"
brew list --cask | sort >> "$f"
```

Each line has its own redirection on purpose. Wrapping them in
`{ ...; } > file` lets VS Code's terminal write its hidden shell-integration
markers (`^[]633;...`) into the file.

### 5. Clean up casks that never really installed

When a cask's `.pkg` step fails, Homebrew can still record the cask as
installed. Check that the app or files actually exist, and remove the record by
hand. `brew uninstall` would call `sudo` again. `${CASK:?}` stops the command
if `CASK` is empty, so it can't delete the whole `Caskroom` folder by mistake.

```bash
ls ~/.local/homebrew/Caskroom/
CASK=xquartz    # a cask that isn't really installed
rm -rf ~/.local/homebrew/Caskroom/"${CASK:?}"
```

### 6. Let GUI apps find `~/.local/bin`

Apps started from the Dock or Finder don't read `~/.bash_profile`. Podman
Desktop, for example, can't find `podman` or run `kind`. Installing a login
agent sets `PATH` for GUI apps each time you log in:

```bash
cat > ~/Library/LaunchAgents/local.setpath.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>local.setpath</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/launchctl</string><string>setenv</string><string>PATH</string>
    <string>${HOME}/.local/bin:${HOME}/.local/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
launchctl bootout "gui/$(id -u)/local.setpath" 2>/dev/null   # in case it's already loaded
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/local.setpath.plist
```

Quit and reopen apps for them to pick up the new `PATH`.

### 7. Podman

Install Podman from the official `.pkg` without running the installer: extract
its files into `~/.local`.

```bash
rm -rf /tmp/podman-pkg    # pkgutil refuses to expand into an existing folder
pkgutil --expand-full ~/Downloads/podman-installer-macos-arm64.pkg /tmp/podman-pkg
P=/tmp/podman-pkg/podman.pkg/Payload/podman
mkdir -p ~/.local/bin ~/.local/lib ~/.local/share
cp "$P"/bin/* ~/.local/bin/
cp "$P"/lib/* ~/.local/lib/
cp -R "$P"/share/krunkit ~/.local/share/
```

Then tell Podman where its helper programs are, and choose the `applehv`
provider. In `~/.config/containers/containers.conf`:

```toml
[engine]
helper_binaries_dir = ["/Users/<you>/.local/bin"]

[machine]
#provider = "libkrun"   # needs libkrun.dylib in /opt/podman/lib or /opt/homebrew/lib (admin only)
provider = "applehv"
```

`krunkit`, the libkrun runner, only looks for `libkrun.dylib` under `/opt`.
macOS ignores `DYLD_LIBRARY_PATH` for signed binaries, so libkrun doesn't work
from `~/.local`. `applehv` (`vfkit`) has no such dependency, and it supports
Rosetta for amd64 images.

Create and start the machine:

```bash
podman machine init --cpus 12 --memory 65536 --disk-size 500 --rootful --now
```

`--memory` is in MiB and `--disk-size` is in GiB. The disk only uses space as
it fills. Size the machine to your hardware. You can change CPUs and memory
later with `podman machine stop` followed by `podman machine set`.

In Podman Desktop, go to **Settings → Preferences**, search for "binary path",
and set the Podman binary path to `~/.local/bin/podman`. The exact setting name
may differ between Podman Desktop versions.

For Kubernetes, create clusters with `kind create cluster`, or with
**Settings → Resources → Kind** in Podman Desktop once step 6 is done.

### Avoid on this setup

| Package | Why |
|---|---|
| `docker-desktop` | It installs with a `sudo` prompt (the PIV PIN prompt on smart-card Macs) and conflicts with Podman. It also changes `~/.docker/config.json` (`credsStore: desktop`), which breaks `docker login` once it's removed. |
| `virtualbox`, `vagrant`, `xquartz` | Their installers need admin rights: kernel or system extensions, `/opt` and system services. |
| `socket_vmnet` | Needs root to provide VM networking, so it does nothing without admin rights. |
| `mysql` | A very long source build, and it's easy to interrupt partway through. Run it in Podman instead: `podman run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=... mysql:8.4`. |

Some packages in `work()` install without admin rights but are limited without it:

| Package | Limitation |
|---|---|
| `postgresql` | Builds from source, which takes a while. The `postgresql` alias follows the newest major version, and data folders from an older major version need a migration. |

Rootless alternatives for packages that need admin:

| Instead of | Use |
|---|---|
| `r-app` cask | `brew install r` |
| `quarto` cask | the `quarto-<ver>-macos.tar.gz` release, extracted into `~/.local` |
| `session-manager-plugin` cask | AWS's bundle zip: `./sessionmanager-bundle/install -i ~/.local/sessionmanagerplugin -b ~/.local/bin/session-manager-plugin` |
| `vagrant` + `virtualbox` | Lima, Colima, or `podman machine` |
| `node@20`, `python@3.x` builds | `nvm`, `uv python install` or `mise` (prebuilt, installed in `$HOME`) |
| `rust` (pulls in an `llvm` build) | `rustup` |

### Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `chsh: ... non-standard shell` | The shell isn't in `/etc/shells`, and only an admin can add it. Ask IT, or set your terminal app to run `~/.local/homebrew/bin/bash -l` as its shell. |
| `bash: .../gsed: No such file or directory` on every prompt | A GNU alias points at a tool that isn't installed. Use the conditional aliases in step 3, or run `brew install gnu-sed grep make`. |
| `sed -i ''` fails with `can't read s/...` | `sed` is aliased to GNU `gsed`, which takes `-i` without the empty argument. Use `sed -i 's/.../.../' file`, or call `/usr/bin/sed` for macOS syntax. |
| `could not find "gvproxy"` | Set `helper_binaries_dir` (step 7). |
| `krunkit was terminated by signal: abort trap` | libkrun can't find `libkrun.dylib`. Switch the provider to `applehv` (step 7). |
| Podman Desktop or Kind: `podman: executable file not found in $PATH` | GUI apps don't read your shell profile. See step 6. |
| `Do you want to proceed with the installation? [y/n]` | Homebrew 7 asks by default. Set `export HOMEBREW_NO_ASK=1`. |
| VPN drops soon after the screen locks | The Mac sleeps one minute after the display turns off (`pmset -g` shows `sleep 1`). Turn on **System Settings → Battery → Options → Prevent automatic sleeping on power adapter when the display is off**, or run `caffeinate -s &`. |

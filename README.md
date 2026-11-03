# configurations

Setup for Apple Silicon Macs: Homebrew in `/opt/homebrew`, the packages to
install, and a shell profile. It works on Macs where you have admin rights all
the time, some of the time, or not at all.

| File | What it is |
|---|---|
| [install.sh](install.sh) | Checks the Mac, then installs or updates the package lists (`work`, `home`, `update`) |
| [.bash_profile](.bash_profile) | Shell profile for this setup. Copy it to `~/.bash_profile` |
| [brew_installs.txt](brew_installs.txt) | Snapshot of what's installed, to compare against `install.sh` |
| [.claude/skills/mac-setup-maintainer](.claude/skills/mac-setup-maintainer/SKILL.md) | Claude Code skill for maintaining this repo, with scripts that check package names and the public profile |
| `Makefile`, `Taskfile.yaml`, `ansible/` | Older, mostly Linux tooling. Not used by this setup |

## New Mac, step by step

Steps 1, 4 and 6 need admin rights once (or IT's help). If your admin rights
are temporary, do those steps while you have them. To check whether you're an
admin right now:

```bash
dseditgroup -o checkmember -m "$USER" admin
```

### 1. Command Line Tools

Homebrew and `git` need Apple's Command Line Tools. Check whether they're
already installed (on managed Macs, IT often installs them):

```bash
xcode-select -p
```

If that prints an error, run `xcode-select --install`. If it asks for an
administrator password you don't have, ask IT to install them.

### 2. Get this repo

```bash
mkdir -p ~/development/github.com/haisamido
cd ~/development/github.com/haisamido
git clone https://github.com/haisamido/configurations.git
cd configurations
```

### 3. Install Homebrew

Homebrew goes in `/opt/homebrew`, its official location on Apple Silicon, so
packages install from prebuilt bottles in minutes.

- **With admin rights,** run the official installer. It creates
  `/opt/homebrew`, makes you the owner, and asks for your password:
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- **Without admin,** the installer can't create `/opt/homebrew`. Have IT run
  this from your account (for example by granting you temporary admin), so
  that `$USER` is you:
  ```bash
  sudo mkdir -p /opt/homebrew
  sudo chown -R "$USER":admin /opt/homebrew
  ```
  Then run the installer command above. It doesn't need `sudo` once the folder
  is yours.

Skip the "Next steps" the installer prints about `~/.zprofile`. Step 5 replaces
them. For now, switch the current window to the new brew:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --prefix    # /opt/homebrew
```

Once `/opt/homebrew` belongs to you, `brew` never needs admin again.

### 4. Install the packages

```bash
./install.sh     # choose 1) Install work, or 4) Install home for work plus home
```

Apps (casks) are only installed if you're an admin. Without admin, `work`
installs the formulae and says it skipped the apps. Once you have admin, choose
`3)` to install just the apps. See [install.sh](#installsh) for what it checks and what each choice
does.

### 5. Shell profile

```bash
cp ~/.bash_profile ~/.bash_profile.bak 2>/dev/null
cp .bash_profile ~/.bash_profile
```

Put anything personal or work-specific (project paths, AWS profiles, git
identities) in `~/.bash_profile.local`. The profile loads it at the end, and it
isn't in the repo, so it stays private. See [Shell profile](#shell-profile) for
what each part does.

### 6. Login shell

macOS ships bash 3.2. Tab completion needs the newer bash that step 4
installed. Making it your login shell needs admin, because `chsh` only accepts
shells listed in `/etc/shells`, which is owned by root:

```bash
echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/bash
```

### 7. Podman

Use the `applehv` provider. Create `~/.config/containers/containers.conf`:

```toml
[machine]
provider = "applehv"
```

Then create and start the machine. Size it to your hardware:

```bash
podman machine init --cpus 12 --memory 65536 --disk-size 500 --rootful --now
podman run --rm hello-world
```

`--memory` is in MiB and `--disk-size` is in GiB. See [Podman](#podman) for
details.

### 8. Log out and back in

This makes every app, including Terminal and VS Code, use the new login shell,
and turns on tap to click. Then open a terminal and check:

```bash
brew --prefix          # /opt/homebrew
echo "$BASH_VERSION"   # 5.x
java -version
code --version
podman ps
```

## install.sh

It runs these checks first, and stops with a message if one fails:

1. **Apple Silicon.** Intel Macs aren't supported.
2. **Homebrew.** It must be installed in `/opt/homebrew` (step 3). The script
   uses that brew even if another one comes first on your `PATH`.
3. **Admin rights.** It checks whether your account is in the `admin` group,
   without calling `sudo`. If not, it carries on and skips the apps (casks)
   later.
4. **Command Line Tools.** If they're missing, it starts Apple's installer.
   Re-run the script when that finishes.

It also turns on tap to click, keeps the Mac awake until it finishes, and
creates `~/development` and `~/.ssh`. Then it shows a menu:

| Choice | Does |
|---|---|
| 1) `work` | Installs the work formulae (`work_formulae`), then the work apps (`work_casks`) if you're an admin. Without admin it skips the apps and says so |
| 2) `work_formulae` | Only the work formulae. Never asks for your password |
| 3) `work_casks` | Only the work apps, for example during an admin window. Asks for your password once |
| 4) `home` | Everything in `work`, then the home formulae and apps (asks to confirm). The apps are skipped without admin, as in `work` |
| 5) `update` | Upgrades formulae, then apps (casks) if you're an admin. Without admin it upgrades the formulae and skips the apps |
| 6) `update_formulae` | Only the formulae. Never asks for your password |
| 7) `update_casks` | Only the apps, if you're an admin. Asks for your password once. Apps that update themselves (VS Code, browsers) are left to their own updaters: `brew upgrade --cask --greedy` upgrades those too |

Formulae never need your password. If you're an admin, it asks for your
password (or smart-card PIN) once, right before the first app, and keeps it
cached so `.pkg` installers don't ask again. If that fails (wrong password,
cancelled, or your admin rights expired), it skips the apps and carries on.

Before any choice changes anything, it checks that every file
in `/opt/homebrew` belongs to you, because `brew` won't run as root. If any
doesn't, it prints the `sudo chown -R` command to fix it. Scanning the whole
folder takes a couple of seconds, which is why it waits until you've chosen.

You can run it again safely: Homebrew skips packages that are already
installed.

## What needs admin

| Location | Contents | Needs admin? |
|---|---|---|
| `/opt/homebrew` | Homebrew and its formulae | Only once, to create it and make you the owner |
| `/Applications` | Apps installed with `brew install --cask` | Yes: only `admin` group members can write there |
| `/Library`, `/usr/local` | Whatever `.pkg` casks install | Yes, and they also ask for your password |

So you need admin for:

- Creating `/opt/homebrew` the first time.
- Installing, upgrading and uninstalling any app (cask). Without admin, apps
  stay on whatever version you have. Most update themselves anyway. With admin,
  `7) update casks only` upgrades the rest.
- Adding a shell to `/etc/shells`, which `chsh` requires.
- macOS updates (`sudo softwareupdate -i -a`).

Formulae never need admin once `/opt/homebrew` is yours.

Don't set an `--appdir` in `HOMEBREW_CASK_OPTS`, or apps go there instead of
`/Applications`.

## Moving from an existing Homebrew

Built formulae have their prefix compiled in, so you can't copy a Homebrew
folder to a new location. Reinstall into `/opt/homebrew` instead. It's quick,
because almost everything is a bottle.

1. **Save what's installed**, including taps:
   ```bash
   <old-prefix>/bin/brew bundle dump --file=~/Brewfile --tap --formula --cask
   ```
2. **Install Homebrew into `/opt/homebrew`** ([step 3](#3-install-homebrew)).
3. **Switch only the current terminal window** to the new brew. Leave
   `~/.bash_profile` alone for now, or every new window loses your tools until
   the reinstall finishes:
   ```bash
   eval "$(/opt/homebrew/bin/brew shellenv)"
   hash -r
   brew --prefix    # /opt/homebrew
   ```
4. **Reinstall** from the same window with `./install.sh` (choose `1) Install work`).
   Apps that are already in `/Applications` fail with
   `It seems there is already an App at …`. Tell Homebrew to take them over:
   ```bash
   brew install --cask --adopt <name> ...
   ```
   `--adopt` only takes over an app that is identical to the one being
   installed. For any that fail, run `brew install --cask --force <name>`. This
   replaces the `.app` but keeps your settings in `~/Library`.
5. **Switch `~/.bash_profile`** ([step 5](#5-shell-profile)). Open a new
   terminal and run the checks in [step 8](#8-log-out-and-back-in).
6. **Delete the old Homebrew** once everything works.

## Shell profile

What [.bash_profile](.bash_profile) does, in order:

- **Docker Desktop's `~/.docker/bin`** goes at the end of `PATH`. Homebrew's
  `docker` and `kubectl` still win, but `docker-credential-desktop` only exists
  there, and `~/.docker/config.json` uses it (`"credsStore": "desktop"`) for
  `docker login` and registry pulls.
- **History** is unlimited and timestamped.
- **Prompt** shows the git branch and short commit hash.
- **Homebrew:** `shellenv` puts `/opt/homebrew/bin` first on `PATH`.
  `HOMEBREW_NO_ASK` stops installs pausing for confirmation, and
  `HOMEBREW_NO_AUTOREMOVE` stops `brew uninstall` removing other packages it
  thinks are unused.
- **GNU tools:** `make`, `date`, `grep`, `head`, `sed` and `readlink` are
  aliased to the GNU versions, but only where they're installed. An alias to a
  missing `gsed` would break every command that runs `sed`, including the
  prompt.
- **Tab completion** comes from `bash-completion@2`, which also loads `task`,
  `kubectl` and `gh` completions. It needs bash 4.2 or newer, so it only works
  once your login shell is Homebrew's bash ([step 6](#6-login-shell)).
- **`DOCKER_HOST`** points `docker`, `act`, `lazydocker` and `dive` at Podman's
  socket. The socket lives in a temporary folder whose path can change, so it's
  looked up each time a shell starts, and it's set only when a Podman machine
  exists: an empty `DOCKER_HOST="unix://"` breaks `docker`.
- **`JAVA_HOME`** and **nvm** use `${HOMEBREW}` rather than a hard-coded path.
- **`~/.bash_profile.local`** is loaded last, for your private settings.

Things to keep out of `~/.bash_profile` and `~/.bash_profile.local`:

- **Anything that prints.** `echo` lines and commands whose errors reach the
  terminal show up in every `bash -lc` call, which confuses VS Code's
  environment lookup and breaks `scp` and `rsync` into this Mac.
- **Slow or network commands**, such as `aws s3 ls`. They run in every new
  shell. If you want them, run them only in interactive shells
  (`[[ $- == *i* ]]`) and send all their output to a file (`> file 2>&1`).
- **Backslashes inside double quotes.** `"…/Visual\ Studio\ Code.app/…"` keeps
  the backslashes as part of the path, so a `PATH` entry never matches.
- **`$PWD#/home/$USER` in the prompt.** Home folders are under `/Users` on
  macOS. Use `\w` instead.

Typing `bash` on its own starts a non-login shell, which reads `~/.bashrc`
rather than `~/.bash_profile`. If you want your aliases and completion there
too, put them in `~/.bashrc` and add `[[ -r ~/.bashrc ]] && . ~/.bashrc` to
`~/.bash_profile`.

## Packages

To see what's installed:

```bash
brew leaves --installed-on-request    # formulae you asked for
brew list --cask
```

Some formulae are installed under another name: `kubectl` is
`kubernetes-cli`, and `python` and `postgresql` are versioned (for example
`python@3.15`, `postgresql@18`).

To save that list to [brew_installs.txt](brew_installs.txt), with these commands as a
header at the top of the file:

```bash
f=brew_installs.txt
cat > "$f" <<'EOF'
# Generated from the repo root with:
#   f=brew_installs.txt
#   cat > "$f" <<'EOF'   # writes this header, up to the closing EOF
#   echo "# formulae" >> "$f"
#   brew leaves --installed-on-request | sort >> "$f"
#   printf '\n# casks\n' >> "$f"
#   brew list --cask | sort >> "$f"

EOF
echo "# formulae" >> "$f"
brew leaves --installed-on-request | sort >> "$f"
printf '\n# casks\n' >> "$f"
brew list --cask | sort >> "$f"
```

Each line has its own redirection on purpose. Wrapping them in
`{ ...; } > file` lets VS Code's terminal write its hidden shell-integration
markers (`^[]633;...`) into the file.

To check whether a cask is a plain app or needs a `.pkg` installer, look at
the **Artifacts** section of `brew info --cask <name>`: `Foo.app (App)` or
`foo.pkg (Pkg)`. `install.sh` always passes `--cask` for casks, because
`brew install` without it picks a formula when one has the same name.

### Clean up casks that never really installed

When a cask's `.pkg` step fails, Homebrew can still record the cask as
installed. Check that the app or files actually exist, then remove the record
by hand. `brew uninstall` would call `sudo` again. `${CASK:?}` stops the command
if `CASK` is empty, so it can't delete the whole `Caskroom` folder by mistake.

```bash
ls /opt/homebrew/Caskroom/
CASK=xquartz    # a cask that isn't really installed
rm -rf /opt/homebrew/Caskroom/"${CASK:?}"
```

## Podman

`podman` and its helpers (`gvproxy`, `vfkit`) come from Homebrew, in
`work_formulae`. You can change the machine's CPUs and memory later with
`podman machine stop` followed by `podman machine set`. The disk only uses
space as it fills.

Each `podman machine start` prints that the system helper service isn't
installed. Ignore it: the helper needs `sudo` to create `/var/run/docker.sock`,
and the `DOCKER_HOST` line in the profile does the same job.

Docker Desktop competes with Podman for the Docker socket. Keep it from
starting automatically if you use Podman.

For Kubernetes, create clusters with `kind create cluster`, or in Podman Desktop
under **Settings → Resources → Kind**.

## Rootless alternatives

If you can't get admin rights, these replace some of the apps:

| Instead of | Use |
|---|---|
| `docker-desktop` | Podman |
| `r-app` cask | The `r` formula (already in `work_formulae`). RStudio finds it automatically |
| `quarto` cask | The `quarto-<ver>-macos.tar.gz` release, extracted into `~/.local` |
| `session-manager-plugin` cask | AWS's bundle zip: `./sessionmanager-bundle/install -i ~/.local/sessionmanagerplugin -b ~/.local/bin/session-manager-plugin` |
| `vagrant` + `virtualbox` | UTM, `qemu`, Lima, or `podman machine` |

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Homebrew isn't installed in /opt/homebrew` | Install it first ([step 3](#3-install-homebrew)). |
| `/opt/homebrew isn't fully owned by …` | The folder, or some files in it, belong to another account or to root, for example if IT created it or after `sudo brew`. Run the `sudo chown -R` command it prints, with admin rights. |
| `It seems there is already an App at '/Applications/…'` | Homebrew doesn't know it installed that app. Run `brew install --cask --adopt <name>`. |
| `Permission denied` installing or upgrading an app | `/Applications` needs admin. Run it while you have admin rights. |
| `chsh: ... non-standard shell` | The shell isn't in `/etc/shells`, and only an admin can add it ([step 6](#6-login-shell)). |
| VS Code's terminal still runs `/bin/bash` after `chsh` | Apps keep the shell from when you logged in. Log out and back in, or set `terminal.integrated.defaultProfile.osx` to a profile with `"path": "/opt/homebrew/bin/bash"` and `"args": ["-l"]`. |
| No tab completion | Your shell is macOS's bash 3.2. Check `echo $BASH_VERSION`, and see [step 6](#6-login-shell). |
| `docker-credential-desktop: executable file not found` | `~/.docker/bin` isn't on `PATH`. Keep the Docker Desktop lines at the top of the profile. |
| `bash: .../gsed: No such file or directory` on every prompt | A GNU alias points at a tool that isn't installed. Use the conditional aliases in the repo's profile. |
| `sed -i ''` fails with `can't read s/...` | `sed` is aliased to GNU `gsed`, which takes `-i` without the empty argument. Use `sed -i 's/.../.../' file`, or `/usr/bin/sed` for macOS syntax. |
| `Do you want to proceed with the installation? [y/n]` | Homebrew 7 asks by default. Set `export HOMEBREW_NO_ASK=1`. |
| VPN drops soon after the screen locks | The Mac sleeps one minute after the display turns off (`pmset -g` shows `sleep 1`). Turn on **System Settings → Battery → Options → Prevent automatic sleeping on power adapter when the display is off**, or run `caffeinate -s &`. |

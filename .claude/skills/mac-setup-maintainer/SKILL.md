---
name: mac-setup-maintainer
description: Maintain this Mac setup repo (install.sh, README.md, .bash_profile, brew_installs.txt) on Apple Silicon Macs where admin rights come and go. Use it whenever the user adds, removes or questions Homebrew packages or casks, edits install.sh or the shell profile, asks whether something is installed or needs admin/sudo, wants the README updated or checked, wants the repo's .bash_profile synced without personal data, or asks to review or validate the setup, even if they don't name a file.
---

# Mac setup maintainer

This repo sets up Apple Silicon Macs: Homebrew in `/opt/homebrew`, package
lists in `install.sh`, and a shell profile. The owner's work Mac only gets
admin rights temporarily, on request, and not reliably, so the setup has to
work without admin and degrade cleanly.

## Repo map

| File | Role |
|---|---|
| `install.sh` | Checks (Apple Silicon, Homebrew in `/opt/homebrew`, admin, Command Line Tools), then a menu: `update` (`update_formulae` then `update_casks`), `update_formulae`, `update_casks`, `work` (`work_formulae` then `work_casks` if admin), `work_formulae`, `work_casks`, `home` |
| `README.md` | New-Mac checklist plus reference sections. It must describe `install.sh` as it actually behaves |
| `.bash_profile` | Public copy of the owner's `~/.bash_profile`, minus personal lines, which live in `~/.bash_profile.local` |
| `brew_installs.txt` | Snapshot of installed formulae and casks |
| `Makefile`, `Taskfile.yaml`, `ansible/` | Older Linux tooling, not part of this setup |

## Ground rules, and why

- **Never run `sudo`, or anything that prompts for a password or PIN.** On the
  owner's managed Mac, a failed `sudo` is logged and may be reported, and sudo
  goes through a PIV smart-card PIN. Give the owner the command to run instead.
  This includes `brew` commands that would install or uninstall a `.pkg` cask.
- **Re-read files before advising or editing.** The owner edits `install.sh`,
  the README and their profile often, between messages. Work from the file on
  disk, not from memory.
- **Update README.md in the same step as any `install.sh` change.** Don't ask
  first. Look for the menu table, the checks list, "What needs admin" and
  Troubleshooting rows that describe what you changed.
- **The repo is public.** No names, emails, `/Users/<name>` paths, employer or
  project names, or AWS profile names in any committed file. Use `${HOME}` and
  `$USER`.
- **Keep scripts bash 3.2 compatible.** `install.sh` may run under macOS's
  `/bin/bash`. Check with both `/bin/bash -n` and `bash -n`, plus `shellcheck`.
  The Bash tool in this environment is also bash 3.2: for anything with arrays
  or nested `$(...)`, write a Python script to the scratchpad and run that.
- **`sed` is GNU `gsed`** in the owner's shell. For in-place edits use the
  Edit tool, Python, or `/usr/bin/sed -i ''` explicitly.
- **Uninstall with `HOMEBREW_NO_AUTOREMOVE=1`.** Plain `brew uninstall` also
  removes every other package it thinks is unused, which once removed 13
  packages unexpectedly. Check `brew uses --installed <name>` first.
- **Don't commit or push.** When asked for a commit message, write it and don't
  run it, and don't mention Claude in it unless asked.

## Adding or removing packages

1. Find out whether the name is a formula or a cask, and what kind of cask:
   ```bash
   python3 .claude/skills/mac-setup-maintainer/scripts/check_packages.py install.sh --only work
   ```
   It reports names that don't exist, duplicates, aliases (`kubectl` is
   `kubernetes-cli`), disabled or deprecated formulae, and for each cask
   whether it's an app, a `.pkg` installer or command-line only. Add
   `--installed` to also check what's actually installed. A name that doesn't
   exist, or a disabled formula, makes the whole `brew install` list fail.
2. Put formulae in `work_formulae` and casks in `work_casks` (or the `home`
   lists), in alphabetical order, one per line with ` \` continuations. Tap
   formulae use their full name (`hashicorp/tap/terraform`), sorted by the part
   after the last `/`.
3. Some names aren't what you'd expect: `g++` comes with `gcc`, and `terraform`
   is only in `hashicorp/tap`. Say so rather than guessing.
4. Mention overlaps the owner may not want, such as a formula and a cask that
   install the same thing (`r` and `r-app`, `docker` and `docker-desktop`).
5. Update the README if the change affects anything it describes.

## What needs admin

- `/opt/homebrew` belongs to the owner, so formulae never need admin.
- Every app cask goes to `/Applications`, which needs admin-group membership.
- `.pkg` casks need admin and a password to install, upgrade and uninstall.
- Command-line-only casks (for example `kiro-cli`) need no admin.
- `install.sh` sets `HAS_ADMIN` from `dseditgroup` at the start, which never
  calls `sudo`. The only `sudo -v` is in `can_install_casks`, right before the
  first cask, and only for admins, so `update_formulae` and formulae never ask for the
  PIN. Keep new sudo-needing steps behind `can_install_casks` (or a function
  like it) rather than prompting at startup.

To check the owner's current admin status without `sudo`:
`dseditgroup -o checkmember -m "$USER" admin`.

## Syncing the repo's .bash_profile

```bash
python3 .claude/skills/mac-setup-maintainer/scripts/check_profile.py .bash_profile --private <comma-separated work terms>
```

It lists lines that differ from `~/.bash_profile` and flags anything personal
in the repo copy. To sync, copy the owner's profile, drop the personal lines
(they belong in `~/.bash_profile.local`), and replace `/Users/<name>` with
`${HOME}`. Ask the owner before editing their own `~/.bash_profile` or
`~/.bash_profile.local`, and back the file up to the scratchpad first.

## Reviewing the setup

When asked to recheck, validate or review:

1. Lint: `/bin/bash -n install.sh && bash -n install.sh && shellcheck install.sh`.
2. Run `check_packages.py`, with `--installed` if they ask what's installed.
3. Read `install.sh` top to bottom and check the logic: the order of the
   checks, every path without admin (does anything still try to write to
   `/Applications`?), messages that match what actually happens, and nothing
   used before it's defined.
4. Check the README against it: menu table, checks list, admin section,
   commands, and internal links (`](#anchor)`) that still resolve.
5. Report findings ranked by impact, with `file:line` links. Fix plain
   inconsistencies in the README directly. For behaviour changes in
   `install.sh`, describe the fix and ask, unless the owner already asked for
   it.

## Regenerating brew_installs.txt

Always keep the generating commands as the header at the top of the file, so
anyone reading it knows how it was made and can redo it.

Each line gets its own redirection, because wrapping the block in `{ ...; } >`
lets VS Code's terminal write its shell-integration escape codes into the file:

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

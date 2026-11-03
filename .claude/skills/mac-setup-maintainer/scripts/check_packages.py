#!/usr/bin/env python3
"""Check every package listed in install.sh against Homebrew.

For each `brew install` list in install.sh it reports:
  - names that don't exist (a bad name makes the whole `brew install` fail)
  - duplicates
  - formula names that are aliases (installed under another name)
  - for casks: whether each is an app (/Applications), a .pkg installer, or
    command-line only, which decides whether it needs admin
  - with --installed: anything listed but not installed

Usage: check_packages.py [path/to/install.sh] [--installed] [--only work]
  --only PREFIX  check only functions whose name starts with PREFIX
Needs only Homebrew and the system python3. Never runs sudo or installs anything.
"""
import json
import os
import re
import subprocess
import sys

BREW = "/opt/homebrew/bin/brew"
ENV = dict(os.environ, HOMEBREW_NO_AUTO_UPDATE="1", HOMEBREW_NO_ENV_HINTS="1")


def brew(*args):
    r = subprocess.run([BREW, *args], capture_output=True, text=True, env=ENV)
    return r.returncode, r.stdout


def lists(src):
    """Yield (function, kind, [names]) for each brew install list."""
    for fn in re.finditer(r"^(\w+)\(\) \{\n(.*?)^\}", src, re.S | re.M):
        name, body = fn.group(1), fn.group(2)
        for m in re.finditer(r"brew install( --cask)? ((?:[^\n]*\\\n)*[^\n]*)", body):
            items = re.findall(r"[A-Za-z0-9@/._+-]+", m.group(2).replace("\\", " "))
            if items and not items[0].startswith("$"):
                yield name, "cask" if m.group(1) else "formula", items


def cask_kind(info):
    kinds = {k for a in info["artifacts"] if isinstance(a, dict) for k in a}
    if kinds & {"pkg", "installer"}:
        return "pkg (needs admin + password)"
    if kinds & {"app", "suite"}:
        return "app (/Applications, needs admin group)"
    return "cli only (no admin)"


def main():
    args = sys.argv[1:]
    only = ""
    if "--only" in args:
        i = args.index("--only")
        only = args[i + 1]
        del args[i : i + 2]
    path = next((a for a in args if not a.startswith("--")), "install.sh")
    check_installed = "--installed" in args
    src = open(path).read()
    problems = 0

    installed_f = installed_c = set()
    if check_installed:
        installed_f = set(brew("list", "--formula", "--full-name")[1].split())
        installed_f |= {n.split("/")[-1] for n in installed_f}
        installed_c = set(brew("list", "--cask")[1].split())

    for fn, kind, items in lists(src):
        if not fn.startswith(only):
            continue
        print(f"\n== {fn}: {len(items)} {kind}{'s' if kind == 'cask' else 'e'}")
        dups = sorted({i for i in items if items.count(i) > 1})
        if dups:
            problems += 1
            print("  DUPLICATE:", " ".join(dups))
        for item in items:
            flag = "--cask" if kind == "cask" else "--formula"
            rc, out = brew("info", flag, "--json=v2", item)
            if rc != 0 or not out.strip():
                problems += 1
                print(f"  NOT FOUND: {item}")
                continue
            data = json.loads(out)["casks" if kind == "cask" else "formulae"][0]
            notes = []
            if kind == "cask":
                notes.append(cask_kind(data))
            else:
                real = data["full_name"] if "/" in item else data["name"]
                if real != item:
                    notes.append(f"alias of {real}")
                if data.get("disabled") or data.get("deprecated"):
                    problems += 1
                    notes.append("DISABLED/DEPRECATED")
            if check_installed:
                have = installed_c if kind == "cask" else installed_f
                real = data.get("token") or data.get("name")
                if item not in have and real not in have and item.split("/")[-1] not in have:
                    problems += 1
                    notes.append("NOT INSTALLED")
            if notes:
                print(f"  {item:28} {'; '.join(notes)}")

    print(f"\n{problems} problem(s)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()

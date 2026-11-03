#!/usr/bin/env python3
"""Compare the user's ~/.bash_profile with the repo's public .bash_profile.

The repo copy is meant to be ~/.bash_profile minus anything personal. This
prints the lines that differ (ignoring blank lines) and flags anything in the
repo copy that looks personal: the user's name or home path, email addresses,
or terms passed with --private.

Usage: check_profile.py [repo/.bash_profile] [--private term1,term2,...]
"""
import getpass
import os
import re
import sys


def lines(path):
    with open(path) as f:
        return [l.rstrip("\n") for l in f if l.strip()]


def main():
    args = sys.argv[1:]
    private = []
    if "--private" in args:
        i = args.index("--private")
        private = [t for t in args[i + 1].split(",") if t]
        del args[i : i + 2]
    repo = args[0] if args else ".bash_profile"
    home = os.path.expanduser("~/.bash_profile")

    mine, public = lines(home), lines(repo)
    only_mine = [l for l in mine if l not in public]
    only_public = [l for l in public if l not in mine]
    print(f"Only in {home} ({len(only_mine)}):")
    for l in only_mine:
        print("  ", l)
    print(f"\nOnly in {repo} ({len(only_public)}):")
    for l in only_public:
        print("  ", l)

    user = getpass.getuser()
    patterns = [re.escape(f"/Users/{user}"), r"[\w.+-]+@[\w-]+\.[\w.]+", rf"\b{re.escape(user)}\b"]
    patterns += [re.escape(t) for t in private]
    hits = [(n, l) for n, l in enumerate(open(repo).read().splitlines(), 1)
            if any(re.search(p, l, re.I) for p in patterns)]
    print(f"\nPossible personal data in {repo}: {len(hits)}")
    for n, l in hits:
        print(f"  {n}: {l}")
    sys.exit(1 if hits else 0)


if __name__ == "__main__":
    main()

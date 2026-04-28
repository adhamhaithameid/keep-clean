#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git -C "$ROOT_DIR" config --local core.hooksPath .githooks
git -C "$ROOT_DIR" config --local commit.template .gitmessage
git -C "$ROOT_DIR" config --local commit.verbose true
git -C "$ROOT_DIR" config --local rerere.enabled true
git -C "$ROOT_DIR" config --local rebase.autosquash true
git -C "$ROOT_DIR" config --local diff.algorithm histogram

cat <<'EOF'
Atomic commit workflow configured for this repository:
  - core.hooksPath=.githooks
  - commit.template=.gitmessage
  - commit.verbose=true
  - rerere.enabled=true
  - rebase.autosquash=true
  - diff.algorithm=histogram

Quick loop:
  git add -p
  git diff --cached
  git commit

Temporary bypass for a legitimately larger commit:
  KEEP_CLEAN_ALLOW_LARGE_COMMIT=1 git commit ...
EOF

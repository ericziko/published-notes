---
created: 2025-09-15T14:38
updated: 2025-09-15T14:41
title: pull-request-review-workflow-conversation-transcript
date created: Monday, September 15th 2025, 9:38:06 pm
date modified: Monday, September 15th 2025, 9:41:08 pm
---

# pull-request-review-workflow-conversation-transcript

**Date:** September 15, 2025 (America/Los_Angeles)

---

**User:**  
I find the online interface in the web browser through GitHub for reviewing pull requests to be anemic and not a great experience 

I can't see the code with the same fidelity as I can when I review a pull requests locally

Can you give me some strategies and tool suggestions around improving my workflow for reviewing pull requests

---

**Assistant:**  
You're not wrong—the GitHub web UI is great for "skim + rubber-stamp," but it's weak for deep code comprehension. Here's a "local-first" review stack that preserves fidelity (your editor, your LSP, your tests) while still flowing cleanly back to GitHub.

# A. Local-first PR workflow (the backbone)

**1) Pull PRs as real local branches/worktrees**
- Teach Git to fetch PR refs so you can treat them like any branch:
  
  ```ini
  # ~/.git/config (or repo .git/config)
  [remote "origin"]
    fetch = +refs/heads/*:refs/remotes/origin/*
    fetch = +refs/pull/*/head:refs/remotes/origin/pr/*
  ```
- Create an isolated worktree per PR (fast, keeps your main tree clean):
  ```bash
  # One-time: ensure PR ref exists (origin/pr/123)
  git fetch origin

  # Make an isolated directory with the PR checked out
  git worktree add ../pr-123 origin/pr/123

  # Jump in and set upstream (optional but handy)
  cd ../pr-123
  git switch -c review/pr-123 --track origin/pr/123
  ```
  Benefits: separate build artifacts, no stash juggling, you can keep multiple PRs open side-by-side.

**2) Compare like a surgeon, not a lumberjack**
- Start broad → narrow:
  ```bash
  # What changed (high level)?
  git diff --compact-summary origin/main...HEAD
  git diff --stat origin/main...HEAD

  # Where did the churn concentrate?
  git diff --dirstat=files,0 origin/main...HEAD
  ```
- Hide noise:
  ```bash
  git -c diff.wsErrorHighlight=all diff -w origin/main...HEAD   # ignore whitespace
  git diff --color-moved=plain origin/main...HEAD               # detect refactors/moves
  ```
- Review by commit when the author curated logical steps:
  ```bash
  git log --oneline --reverse origin/main..HEAD
  git show <commit>
  ```
  You'll catch "oops rolled two concerns into one commit" instantly.

**3) Use a code-aware diff and a readable pager**
- Turn on a smarter pager (syntax-highlighting, side-by-side, intra-line):
  ```ini
  # ~/.gitconfig
  [core]
    pager = delta
  [delta]
    navigate = true
    side-by-side = true
    line-numbers = true
  [interactive]
    diffFilter = delta --color-only
  [merge]
    conflictStyle = zdiff3
  ```
- For semantic diffs (AST-aware), wire up **difftastic** as an external diff:
  ```ini
  [diff]
    tool = difftastic
  [difftool "difftastic"]
    cmd = difft "$LOCAL" "$REMOTE"
  ```
  Then:
  ```bash
  git difftool -t difftastic origin/main...HEAD
  ```
  This helps with "giant function moved + tiny edit" cases.

**4) Navigate with your editor's superpowers**
- Open the worktree in your IDE so LSP, go-to-definition, find-refs, type hints, and tests all work. This alone is the fidelity win you're after.
- Validate behavior locally:
  ```bash
  # Run focused tests impacted by changed files (example pattern)
  git diff --name-only origin/main...HEAD |     grep -E '(.cs|.ts|.py)$' |     xargs -I{} ./scripts/map-to-tests.sh {} |     xargs -r dotnet test --filter FullyQualifiedName~   # adapt to your stack
  ```

**5) Sanity-check incremental updates**
- When the author pushes new commits, review the delta between review rounds:
  ```bash
  # Compare two versions of the PR tip
  git range-diff origin/main...old_tip origin/main...new_tip
  ```
  Range-diff is the antidote to "force-pushed, what actually changed?"

# B. GitHub CLI + editor integration (comment from the comfort of $EDITOR)

**GitHub CLI (gh)**
- Pull, view, diff, comment, and submit reviews without leaving the terminal:
  ```bash
  gh auth login
  gh pr list
  gh pr checkout 123
  gh pr view --web             # or show metadata inline
  gh pr diff                   # quick inline diff
  gh pr review --comment --body-file notes.md
  gh pr review --request-changes --body "Edge case X fails"
  gh pr review --approve
  ```
  You can script your "open, diff, test, lint, review" pipeline around `gh`.

**VS Code: GitHub Pull Requests & Issues**
- Browse PRs, check out branches, see file comments inline, start/submit reviews directly from the editor.
- Killer feature: comment on a line with your cursor where your LSP context lives. Lower cognitive load, higher signal.

**JetBrains IDEs (Rider/IntelliJ/CLion)**
- Built-in "Pull Requests" tool window lets you check out, run tests, comment inline, and submit the review—all inside the IDE.

# C. Visual diff/merge tools (when structure matters)

Sometimes you just need a great visual diff:
- **Beyond Compare**, **Kaleidoscope** (macOS), **Meld**, **WinMerge**, **Araxis Merge**.
- Wire one in as your difftool/mergetool to examine complex renames/moves quickly:
  ```ini
  [diff]
    tool = bc  # e.g., Beyond Compare
  [difftool "bc"]
    cmd = bcomp "$LOCAL" "$REMOTE"
  ```

# D. Better "hosted" review experiences (when the team can adopt changes)

- **Reviewable.io**: richer file state, per-commit review, robust "done" tracking, smarter threading. Excellent for large/long-running PRs.
- **Gerrit** (or Gerrit-style): commit-by-commit review with "Change" objects and inline CI. Great for very large monorepos, but heavier adoption cost.
- **Stacked PR tooling** for incremental, digestible reviews:
  - **Graphite** or **ghstack**: create a series of small dependent PRs with proper review diffs between them. Reviews get dramatically easier.

# E. Make the PRs themselves reviewable (team policies)

These aren't tools; they're force multipliers that make every UI better:

1. **Small, single-purpose PRs**  
   Cap ~200–400 lines of *effective* changes. If it's bigger, split by concern.

2. **Commit hygiene**  
   Encourage logical commits with helpful messages. Reviewers can meaningfully do "commit-by-commit."

3. **PR templates & checklists**  
   - Context/why
   - Risk areas & rollback plan
   - Test evidence (screens, metrics, commands run)
   - Known non-goals
   This cuts your time hunting for intent.

4. **Label the kind of change** (feature/bug/security/refactor) and **surface blast radius** (e.g., "touches Auth middleware + API Gateway routes").

5. **Pre-submit gates**  
   Auto-run formatters, static analyzers, and fast tests locally (git hooks or pre-push) so reviewers aren't sifting through style nits and obvious failures.

# F. Handy commands & tricks (copy/paste tier)

- Show only renamed/moved lines (helps spot real edits):
  ```bash
  git diff --color-moved=plain origin/main...HEAD
  ```
- Word-level diff for text-heavy files (docs, JSON):
  ```bash
  git diff --word-diff origin/main...HEAD
  ```
- Focus on a directory or glob:
  ```bash
  git diff origin/main...HEAD -- src/Payments/**/*.cs
  ```
- Review generated files off by default:
  ```gitignore
  # .gitattributes
  *.snap diff=off
  *.min.js diff=off
  ```
- Speed up context seeking:
  ```bash
  rg --hidden --glob '!bin' --glob '!obj' 'theThingWeChanged'
  ```

# G. A "batteries-included" review script (drop-in)

Save this as `scripts/review-pr.sh` and make it executable:

```bash
#!/usr/bin/env bash
set -euo pipefail

PR="${1:?Usage: review-pr.sh <pr-number>}"
BASE="${2:-origin/main}"
ROOT="$(pwd)"
DIR="$ROOT/../pr-$PR"

git fetch origin "+refs/pull/*/head:refs/remotes/origin/pr/*"

if [ ! -d "$DIR" ]; then
  git worktree add "$DIR" "origin/pr/$PR"
fi

cd "$DIR"

echo "== Stats =="
git diff --stat "$BASE"...HEAD

echo
echo "== Dirstat (hotspots) =="
git diff --dirstat=files,0 "$BASE"...HEAD

echo
echo "== Moved/Refactor aware diff (ignore whitespace) =="
git -c diff.wsErrorHighlight=all diff -w --color-moved=plain "$BASE"...HEAD | ${PAGER:-less -R}

echo
echo "== Run fast checks =="
# Adapt these for your stack
if command -v dotnet >/dev/null; then
  dotnet build -clp:ErrorsOnly
  dotnet test --no-build
fi

echo
echo "== Range-diff since last review (optional) =="
# If you tag last reviewed tip: git tag -f last-reviewed HEAD (before updates)
if git rev-parse -q --verify last-reviewed >/dev/null; then
  git range-diff "$BASE"...last-reviewed "$BASE"...HEAD
fi
```

# H. Putting it together (three good paths)

- **Editor-centric**: VS Code or JetBrains PR integration + local worktrees + delta/difftastic + gh for submitting the final review.
- **CLI-centric**: worktrees + delta/difftastic + `gh pr` + your own scripts (like above) + a visual difftool for hairy files.
- **Hosted-plus**: switch to Reviewable (or adopt stacked PRs with Graphite/ghstack) to fix the experience at the source.

Pick one path and run it for a week; the difference is night-and-day. Next step I'd add is a tiny team PR template and a shared `review-pr.sh` so everyone's review muscle memory gets consistent and fast.

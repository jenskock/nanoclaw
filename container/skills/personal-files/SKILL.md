---
name: personal-files
description: List and search the user's personal files mounted at /workspace/personal-files. Use when the user asks about "my files", "my notes", or to find content in their personal folder.
allowed-tools: Bash(personal-files*)
---

# Personal Files Helper

The user's personal files are mounted at `/workspace/personal-files`. Use this helper for quick listing and content search.

## Commands

```bash
personal-files list [subdir]           # List contents of /workspace/personal-files or a subdir
personal-files search "pattern" [subdir]  # Find text files containing pattern under the tree
```

- **list** — Shows directory contents (e.g. `personal-files list`, `personal-files list projects`). Subdir is relative to `/workspace/personal-files`.
- **search** — Greps for the pattern in common text file types (md, txt, py, js, json, yaml, html, etc.) under the given subdir (default: root). Output is a list of matching file paths, limited to 100.

## When to use

- User says "what's in my personal files?", "list my notes", "show my files".
- User asks to "search my files for X" or "find where I wrote about Y".
- You need to discover structure before reading specific files with standard tools (cat, head, etc.).

## How to run

From the container, run the script with `sh` (skill dir is synced into each group's `.claude/skills`):

```bash
sh /home/node/.claude/skills/personal-files/personal-files list
sh /home/node/.claude/skills/personal-files/personal-files search "query"
```

## Direct access

You can also use standard shell commands on `/workspace/personal-files`: `ls`, `find`, `cat`, `head`, etc. Use the helper when you want a quick listing or content search without building find/grep yourself.

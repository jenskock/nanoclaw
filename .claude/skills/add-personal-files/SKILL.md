---
name: add-personal-files
description: Mount a user-defined personal files directory so the agent can read, search, and (when asked) edit files. Supports Q&A over documents and folder navigation.
---

# Add Personal Files

This skill mounts a single user-chosen directory (and its subfolders) into each agent container at `/workspace/personal-files`. The agent can read, search, summarize, and navigate the tree; it may create, edit, or delete files there only when the user explicitly asks.

**How it works:**
- You set `PERSONAL_FILES_DIR` (in `.env` or environment) to the absolute path of your personal files folder on the host.
- The container runner mounts that path at `/workspace/personal-files` for every group. The folder can contain anything: projects, notes, PDFs, PowerPoints, etc.
- Agent instructions in `groups/global/CLAUDE.md` tell the agent where the mount is and how to use it (read/search by default; write only when requested).

## Phase 1: Pre-flight

### Check if already applied

Read `.nanoclaw/state.yaml`. If `add-personal-files` is in `applied_skills`, skip to Phase 3 (Setup). The code changes are already in place.

If the skills system is not used, check that `src/config.ts` exports `PERSONAL_FILES_DIR` and `src/container-runner.ts` adds the personal-files mount in `buildVolumeMounts()` when `PERSONAL_FILES_DIR` is set.

## Phase 2: Apply Code Changes

### Initialize skills system (if needed)

If `.nanoclaw/` directory doesn't exist yet:

```bash
npx tsx scripts/apply-skill.ts --init
```

### Apply the skill

```bash
npx tsx scripts/apply-skill.ts .claude/skills/add-personal-files
```

This merges the skill's `modify/` files into `src/config.ts` and `src/container-runner.ts`, and records the application in `.nanoclaw/state.yaml`.

If the apply script is not available or reports merge conflicts, apply manually:

1. **config.ts:** Add `'PERSONAL_FILES_DIR'` to the `readEnvFile([...])` array and add the `PERSONAL_FILES_DIR` export as described in `modify/src/config.ts.intent.md`.
2. **container-runner.ts:** Add `PERSONAL_FILES_DIR` to the config import and insert the personal-files mount block in `buildVolumeMounts()` as described in `modify/src/container-runner.ts.intent.md`.

Alternatively, copy the full files from `.claude/skills/add-personal-files/modify/src/` to `src/` (overwriting `config.ts` and `container-runner.ts`), then resolve any conflicts with your local changes.

### Validate

```bash
npm run build
```

Build must be clean before proceeding.

## Phase 3: Setup (mapping the host folder)

Ask the user for the **absolute path** to their personal files directory on the host (e.g. `~/Documents/MyFiles`, `~/personal`, or `C:\Users\Me\Documents` on Windows). The folder may contain any structure and file types (notes, PDFs, presentations, code, etc.).

Set the path so the NanoClaw process can read it:

**Option A — .env (recommended)**

In the project root, add or edit `.env`:

```
PERSONAL_FILES_DIR=/absolute/path/to/personal-files
```

Use an absolute path. On Unix, `~` is not expanded in `.env`; use e.g. `/Users/you/Documents/personal` instead of `~/Documents/personal`.

**Option B — environment**

Export before starting NanoClaw:

```bash
export PERSONAL_FILES_DIR=/absolute/path/to/personal-files
```

If `PERSONAL_FILES_DIR` is empty or unset, no personal-files mount is added. If the path does not exist at runtime, the mount is skipped (no crash).

## Phase 4: Update group CLAUDE.md (agent instructions)

The agent must know about the personal files mount and how to use it. Add a **Personal Files** section to `groups/global/CLAUDE.md` (and optionally to each group's `CLAUDE.md` if you want it only in certain groups).

Read the current `groups/global/CLAUDE.md`, then add the following section (for example after "Your Workspace" or "Long-Term Memory"):

```markdown
## Personal Files

You have access to the user's personal files at `/workspace/personal-files`. This is a single directory tree that can contain anything: projects, notes, PDFs, presentations, spreadsheets, etc.

**Scope:** Only paths under `/workspace/personal-files` are the user's personal files. Do not read or write outside this tree for "personal files" requests.

**Reading and searching:** When the user asks about "my files", "my notes", "in my personal folder", or similar, use `/workspace/personal-files` as the root. You may:
- List and navigate folders (e.g. `ls`, `find`, or the `personal-files` helper if present).
- Read and summarize text-based files (markdown, code, CSV, etc.).
- For PDFs or other binary formats, use available tools (e.g. `pdftotext`, or the pdf-reader skill if installed).
- Search for content (e.g. `grep`, `rg`, or the `personal-files search` helper).

**Writing:** Create, edit, or delete files or folders under `/workspace/personal-files` **only when the user explicitly asks** (e.g. "add a note to my files", "edit that document", "delete that file"). Do not modify personal files on your own initiative.

**Interaction styles:**
- *Q&A:* Answer questions by searching and reading relevant files, then synthesize an answer.
- *Navigation:* List directories, find recent or large files, or help the user locate a file by name or content.
```

If you added a `personal-files` helper script (see Phase 6), mention it in the section, for example:

```markdown
You can use the `personal-files` command for quick listing and search: `personal-files list [subdir]`, `personal-files search "query"`.
```

## Phase 5: Rebuild and Restart

Containers must be rebuilt so they pick up the new mount (no agent-runner code change, but the host binary that builds mount args has changed). Restart the service so it reads `PERSONAL_FILES_DIR` and mounts the directory.

```bash
./container/build.sh
```

Then restart:

```bash
# macOS (launchd)
launchctl kickstart -k gui/$(id -u)/com.nanoclaw

# Linux (systemd)
systemctl --user restart nanoclaw
```

## Phase 6: Verify

1. From a group, ask the agent: "List the top-level items in my personal files directory" or "What's in /workspace/personal-files?". The agent should list contents of the mounted folder.
2. Ask the agent to open or summarize a known file in that folder (e.g. a note or PDF). It should be able to read and describe it.
3. Optionally ask the agent to create or edit a file in that folder and confirm it only does so when you explicitly request it.

## Troubleshooting

### Agent says there is no personal-files directory or folder is empty

- Confirm `PERSONAL_FILES_DIR` is set in `.env` or the environment used by the NanoClaw process.
- Confirm the path exists on the host and is absolute (or relative to the process cwd).
- Restart the service after changing `.env`.
- Check container logs for mount list: `tail -100 groups/main/logs/container-*.log` and look for `/workspace/personal-files` in the Mounts section.

### Permission denied when reading or writing files

- The container runs as a specific user (often uid 1000). Ensure the host directory and its contents are readable (and writable if you want the agent to edit). On macOS/Linux, `chmod` or ownership may need adjustment.

### Personal files not mounted after applying the skill

- Rebuild the container and restart: `./container/build.sh` then `launchctl kickstart -k gui/$(id -u)/com.nanoclaw` (or systemctl restart).
- Ensure `src/container-runner.ts` contains the personal-files block in `buildVolumeMounts()` and that `PERSONAL_FILES_DIR` is imported from config.

## Removal

To disable personal files access:

1. Remove or comment out `PERSONAL_FILES_DIR` from `.env` (or unset the environment variable). Restart the service. No mount will be added.
2. Optionally remove the code changes: in `src/config.ts` remove the `PERSONAL_FILES_DIR` export and its entry in `readEnvFile`; in `src/container-runner.ts` remove `PERSONAL_FILES_DIR` from the config import and remove the "Personal files directory" block in `buildVolumeMounts()`.
3. Remove the "Personal Files" section from `groups/global/CLAUDE.md` (and any group-specific CLAUDE.md that had it).
4. Rebuild and restart: `./container/build.sh` and restart the service.

## Optional: personal-files helper script

For richer listing and search from inside the container, you can add a small script under `container/skills/personal-files/` that the agent can run via bash. See the optional helper tooling in the skill's `container/skills/personal-files/` directory; if present, sync it into each group's skills and document its usage in the Personal Files section of CLAUDE.md.

---
name: add-long-term-memory
description: Add persistent long-term memory to NanoClaw agents. Memories survive context window resets by being saved to memory.md and restored automatically before compaction.
---

# Add Long-Term Memory

This skill gives NanoClaw agents a persistent `memory.md` file that survives context window limits.

**How it works:**
- The agent writes important facts to `/workspace/group/memory.md` during conversations
- When the context window fills and compaction is triggered, the PreCompact hook reads `memory.md` and injects it as a `systemReminder` into the new context window
- Facts are never lost to compaction — the agent always has access to what it has remembered

## Phase 1: Pre-flight

### Check if already applied

Read `.nanoclaw/state.yaml`. If `add-long-term-memory` is in `applied_skills`, skip to Phase 3 (Update group CLAUDE.md files). The code changes are already in place.

## Phase 2: Apply Code Changes

### Initialize skills system (if needed)

If `.nanoclaw/` directory doesn't exist yet:

```bash
npx tsx scripts/apply-skill.ts --init
```

### Apply the skill

```bash
npx tsx scripts/apply-skill.ts .claude/skills/add-long-term-memory
```

This:
- Three-way merges the enhanced PreCompact hook into `container/agent-runner/src/index.ts`
- Records the application in `.nanoclaw/state.yaml`

If the apply reports merge conflicts, read `modify/container/agent-runner/src/index.ts.intent.md` to understand what changed and resolve manually.

### Validate

```bash
npm run build
```

Build must be clean before proceeding.

## Phase 3: Update Group CLAUDE.md Files

The agent needs instructions on how to use memory. Update `groups/global/CLAUDE.md` with a Long-Term Memory section.

Read the current `groups/global/CLAUDE.md`, then add or replace the Memory section with:

```markdown
## Long-Term Memory

You maintain a persistent memory file at `/workspace/group/memory.md`. This file survives context window resets — when the context is compacted, your memory is automatically restored.

**Actively maintain memory.md.** Update it whenever you:
- Learn something important about the user (name, preferences, habits, location, relationships)
- Complete a significant task or project milestone
- The user explicitly asks you to remember something
- Discover context that will matter in future conversations

**Format — use clear categories:**

```
## About the User
- Name: ...
- Location: ...
- Occupation: ...

## Preferences
- Communication style: ...
- Preferred tools/languages: ...

## Ongoing Projects
- Project name: brief status

## Important Context
- Key facts that affect how you should respond

## Reminders
- Things the user wants to be reminded of
```

**Reading memory:** At the start of each conversation, check if `memory.md` exists and read it to restore context. When the user references something from the past that you don't recall, read `memory.md` first before saying you don't remember.

Keep `memory.md` concise — under 300 lines. Archive older entries to `memory-archive.md` if needed.
```

### Update existing group CLAUDE.md files

Also read each group's `CLAUDE.md` file under `groups/` (skip `global/`) and add the same memory instructions if they don't already have a Long-Term Memory section.

For each group directory in `groups/`:
```bash
ls groups/
```

Read `groups/{name}/CLAUDE.md` and add the Long-Term Memory section if missing.

## Phase 4: Update Existing Groups' Agent Runner

The agent-runner source is copied per-group the first time a group runs. Existing groups have a stale copy that won't have the memory hook. Update them:

```bash
# Find all per-group agent-runner-src directories
ls data/sessions/
```

For each group in `data/sessions/`, copy the updated `index.ts` to their agent-runner-src:

```bash
for dir in data/sessions/*/; do
  src="$dir/agent-runner-src/index.ts"
  if [ -f "$src" ]; then
    cp container/agent-runner/src/index.ts "$src"
    echo "Updated: $src"
  fi
done
```

This ensures all existing groups immediately get the memory hook, not just new ones.

## Phase 5: Create Initial memory.md Files

Create a starter `memory.md` in any group folder that doesn't have one yet:

```bash
for dir in groups/*/; do
  name=$(basename "$dir")
  if [ "$name" = "global" ]; then continue; fi
  memfile="$dir/memory.md"
  if [ ! -f "$memfile" ]; then
    cat > "$memfile" << 'EOF'
## About the User

## Preferences

## Ongoing Projects

## Important Context

## Reminders
EOF
    echo "Created: $memfile"
  fi
done
```

## Phase 6: Rebuild and Restart

The container image needs to be rebuilt with the updated agent-runner:

```bash
./container/build.sh
```

Then restart the service:

```bash
# Linux (systemd)
systemctl --user restart nanoclaw

# macOS (launchd)
launchctl kickstart -k gui/$(id -u)/com.nanoclaw
```

## Phase 7: Verify

Tell the user:

> Long-term memory is now active. The agent will maintain a `memory.md` file in each group's workspace. When the context window fills and compaction happens, the memory file is automatically restored so the agent never forgets important facts.
>
> To test it: tell the agent something to remember (e.g., "remember that I prefer concise responses"), then ask it to confirm it remembered. You can also view the memory file directly at `groups/{group-name}/memory.md`.

## Troubleshooting

### Agent doesn't seem to remember things after long conversations

Check that the memory hook is firing:
```bash
tail -50 groups/*/logs/container-*.log | grep -i memory
```

Look for:
- `Injecting memory.md into compacted context as systemReminder` — hook is working
- `Failed to read memory.md` — file permission issue
- No memory lines — the hook file wasn't updated for that group (re-run Phase 4)

### memory.md is empty

The agent writes to it proactively but only after having things to remember. You can seed it manually or ask the agent to "update your memory with what we've discussed".

### Container build fails

If `./container/build.sh` fails, check `container/agent-runner/src/index.ts` compiles cleanly:
```bash
cd container/agent-runner && npx tsc --noEmit
```

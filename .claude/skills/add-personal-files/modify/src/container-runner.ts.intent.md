# Intent: src/container-runner.ts modifications

## What changed

1. Import `PERSONAL_FILES_DIR` from config.
2. In `buildVolumeMounts()`, add a conditional mount of the user's personal files directory to `/workspace/personal-files` when `PERSONAL_FILES_DIR` is set and the path exists on the host.

## Key sections

### Import from config

**Before:** Import list does not include `PERSONAL_FILES_DIR`.

**After:** Add `PERSONAL_FILES_DIR` to the destructuring from `'./config.js'`:

```typescript
import {
  CONTAINER_IMAGE,
  CONTAINER_MAX_OUTPUT_SIZE,
  CONTAINER_TIMEOUT,
  CREDENTIAL_PROXY_PORT,
  DATA_DIR,
  GROUPS_DIR,
  IDLE_TIMEOUT,
  PERSONAL_FILES_DIR,
  TIMEZONE,
} from './config.js';
```

### buildVolumeMounts() — new block

**Location:** After the IPC mount block (the `mounts.push` for `groupIpcDir` → `/workspace/ipc`), and before the "Copy agent-runner source" comment.

**Insert:**

```typescript
  // Personal files directory (user-configured; mounted when PERSONAL_FILES_DIR is set)
  if (PERSONAL_FILES_DIR) {
    const personalPath = path.isAbsolute(PERSONAL_FILES_DIR)
      ? PERSONAL_FILES_DIR
      : path.resolve(process.cwd(), PERSONAL_FILES_DIR);
    if (fs.existsSync(personalPath)) {
      mounts.push({
        hostPath: personalPath,
        containerPath: '/workspace/personal-files',
        readonly: false,
      });
    }
  }
```

- Mount is read-write so the agent can create/edit/delete files when the user asks.
- If the path does not exist, the mount is skipped (no error).
- Relative paths are resolved against `process.cwd()` (project root).

## Invariants

- All existing mounts and their order are unchanged except for the new optional block.
- `buildContainerArgs()`, `runContainerAgent()`, and all other functions are untouched.
- Additional mount validation via `validateAdditionalMounts` is unchanged.
- Container lifecycle, output parsing, and timeout behavior are unchanged.

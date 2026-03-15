# Intent: src/config.ts modifications

## What changed

Added support for an optional personal files directory path used for container mounts. The path is read from `.env` or `process.env` as `PERSONAL_FILES_DIR`.

## Key sections

### readEnvFile keys

**Before:** `readEnvFile(['ASSISTANT_NAME', 'ASSISTANT_HAS_OWN_NUMBER'])`

**After:** Add `'PERSONAL_FILES_DIR'` to the array:

```typescript
const envConfig = readEnvFile([
  'ASSISTANT_NAME',
  'ASSISTANT_HAS_OWN_NUMBER',
  'PERSONAL_FILES_DIR',
]);
```

### New export

After `ASSISTANT_HAS_OWN_NUMBER` and before `POLL_INTERVAL`, add:

```typescript
// Optional: host path to user's personal files directory (mounted at /workspace/personal-files in containers)
export const PERSONAL_FILES_DIR =
  process.env.PERSONAL_FILES_DIR || envConfig.PERSONAL_FILES_DIR || '';
```

If unset or empty, no personal-files mount is added. The path can be absolute or relative to the project root.

## Invariants

- All other config exports unchanged
- No new npm dependencies
- PERSONAL_FILES_DIR is not a secret; it is only a path and can be read from .env

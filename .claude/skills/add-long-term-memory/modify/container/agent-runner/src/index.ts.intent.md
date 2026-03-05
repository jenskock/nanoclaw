# Intent: container/agent-runner/src/index.ts modifications

## What changed

Enhanced `createPreCompactHook` to read `/workspace/group/memory.md` and return it as a `systemMessage` so key facts survive context compaction.

## Key sections

### createPreCompactHook function

The existing conversation archiving logic is preserved unchanged. After the archive step, a new block reads `memory.md`:

```typescript
// Read memory.md and inject into the compacted context so key facts survive
const memoryPath = '/workspace/group/memory.md';
if (fs.existsSync(memoryPath)) {
  try {
    const memory = fs.readFileSync(memoryPath, 'utf-8').trim();
    if (memory) {
      log('Injecting memory.md into compacted context as systemMessage');
      return {
        systemMessage: `## Long-Term Memory (restored after context compaction)\n\nThe following facts were saved to /workspace/group/memory.md:\n\n${memory}\n\n---\nKeep /workspace/group/memory.md up to date with important facts learned in this conversation.`,
      };
    }
  } catch (err) {
    log(`Failed to read memory.md: ${err instanceof Error ? err.message : String(err)}`);
  }
}
return {};
```

The `systemMessage` field is injected into the new context window by the Claude Code SDK after compaction, restoring the agent's memory without consuming the full context.

## Invariants (must-keep)

- All existing conversation archiving logic unchanged
- All allowedTools entries unchanged
- nanoclaw MCP server config unchanged
- All other query options (permissionMode, hooks, env, etc.) unchanged
- MessageStream class unchanged
- IPC polling logic unchanged
- Session management unchanged
- createSanitizeBashHook unchanged

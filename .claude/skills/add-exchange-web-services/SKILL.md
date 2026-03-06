---
name: add-exchange-web-services
description: Add Microsoft Exchange inbox and calendar access to NanoClaw. The agent can read emails and meeting schedules to deliver morning briefings and evening debriefings. Uses EWS SOAP API with NTLM authentication — no Azure app registration required.
---

# Add Exchange Web Services Integration

This skill gives the NanoClaw agent tools to read your Exchange inbox and calendar via the EWS SOAP API (NTLM auth). Once applied, the agent can:

- Read unread emails and summarize them
- Fetch today's (or any day's) calendar events
- Deliver a morning briefing and evening debriefing on a schedule

## Phase 1: Pre-flight

### Check if already applied

Read `.nanoclaw/state.yaml`. If `exchange-web-services` is in `applied_skills`, skip to Phase 9 (Verify).

## Phase 2: Inform the User About Credentials

Tell the user:

> Before I apply the code changes, you need to add your Exchange credentials to `.env`. Open the file at the root of this project and add these three lines:
>
> ```
> EWS_URL=https://mail.yourcompany.com/EWS/Exchange.asmx
> EWS_USERNAME=DOMAIN\username
> EWS_PASSWORD=yourpassword
> ```
>
> - `EWS_URL` — the full EWS endpoint of your Exchange server
> - `EWS_USERNAME` — usually `DOMAIN\username` for on-premise, or `username@company.com` for Exchange Online
> - `EWS_PASSWORD` — your Exchange password
>
> `.env` is gitignored and never committed. Let me know when you've added them and I'll continue.

Wait for the user to confirm before proceeding to the next phase.

## Phase 3: Expose Secrets to the Container

Edit `src/container-runner.ts`. Find the `readSecrets()` function — it calls `readEnvFile([...])` with a list of allowed key names. Add the three Exchange keys to that array:

```typescript
function readSecrets(): Record<string, string> {
  return readEnvFile([
    'CLAUDE_CODE_OAUTH_TOKEN',
    'ANTHROPIC_API_KEY',
    'ANTHROPIC_BASE_URL',
    'ANTHROPIC_AUTH_TOKEN',
    'EWS_URL',
    'EWS_USERNAME',
    'EWS_PASSWORD',
  ]);
}
```

## Phase 4: Install EWS Scripts

Create the directory `scripts/exchange/` in the project root and copy the three scripts from the skill folder:

```bash
mkdir -p scripts/exchange
cp .claude/skills/add-exchange-web-services/scripts/get_inbox.sh scripts/exchange/
cp .claude/skills/add-exchange-web-services/scripts/get_inbox_full.sh scripts/exchange/
cp .claude/skills/add-exchange-web-services/scripts/get_calendar_day.sh scripts/exchange/
chmod +x scripts/exchange/*.sh
```

These scripts will be accessible inside the agent container at `/workspace/project/scripts/exchange/`.

## Phase 5: Add `xmllint` to the Container

The `get_inbox_full.sh` script uses `xmllint` to parse XML. Edit `container/Dockerfile`. In the `apt-get install` block, add `libxml2-utils` to the list of packages:

```dockerfile
RUN apt-get update && apt-get install -y \
    chromium \
    ...
    libxml2-utils \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*
```

Add `libxml2-utils \` on its own line after the last existing package and before `curl \`.

## Phase 6: Add Agent Instructions

Append the following section to `groups/global/CLAUDE.md` (before the "Message Formatting" section if it exists, otherwise at the end):

```markdown
## Exchange Email & Calendar

You have access to Exchange Web Services (EWS) tools via bash scripts. The credentials are available as environment variables: `$EWS_URL`, `$EWS_USERNAME`, `$EWS_PASSWORD`.

### Read inbox (summary, last 20 emails)

```bash
EWS_URL="$EWS_URL" USERNAME="$EWS_USERNAME" PASSWORD="$EWS_PASSWORD" \
  bash /workspace/project/scripts/exchange/get_inbox.sh
```

### Read inbox with full email body (last 10 emails, two-step fetch)

```bash
EWS_URL="$EWS_URL" USERNAME="$EWS_USERNAME" PASSWORD="$EWS_PASSWORD" \
  bash /workspace/project/scripts/exchange/get_inbox_full.sh
```

### Read calendar for a specific day

```bash
EWS_URL="$EWS_URL" USERNAME="$EWS_USERNAME" PASSWORD="$EWS_PASSWORD" \
  bash /workspace/project/scripts/exchange/get_calendar_day.sh YYYY-MM-DD
```

### Morning Briefing

When asked for a morning briefing (or on a scheduled morning task), run both the inbox and calendar scripts for today, then deliver a concise summary:

- *Inbox*: number of unread emails, top senders, subject lines of the most important emails
- *Calendar*: today's meetings in chronological order with time, title, and location/link

Keep it brief. Use bullet points. No markdown — WhatsApp/Telegram formatting only.

### Evening Debriefing

When asked for an evening debriefing (or on a scheduled evening task), check today's calendar (which meetings happened) and any inbox activity since morning, then deliver:

- Meetings that took place today
- Important emails that arrived during the day
- Any follow-ups or action items the user should know about

### Parsing the XML responses

The scripts return raw EWS XML. Extract the relevant fields using `grep` and `sed`, or use `xmllint --xpath` if available. Key fields to extract:

- Emails: `Subject`, `From/Name`, `DateTimeReceived`, `IsRead`, `Body`
- Calendar: `Subject`, `Start`, `End`, `Location`, `IsAllDayEvent`, `Organizer/Name`

If the XML is large, focus on the most recent or most important items rather than parsing everything.
```

## Phase 7: Record Application

Update `.nanoclaw/state.yaml` to record this skill was applied. If the file doesn't exist, create it:

```yaml
applied_skills:
  - exchange-web-services
```

If it already exists, append `- exchange-web-services` under `applied_skills`.

## Phase 8: Rebuild and Restart

Rebuild the container (Dockerfile changed):

```bash
cd container && ./build.sh
```

Then compile and restart:

```bash
npm run build
systemctl --user restart nanoclaw   # Linux
# macOS: launchctl kickstart -k gui/$(id -u)/com.nanoclaw
```

Tell the user:

> Exchange integration is ready. You can now ask me things like:
> - "Give me my morning briefing"
> - "What meetings do I have today?"
> - "Any important emails?"
> - "Give me an evening debriefing"
>
> You can also set up a daily morning briefing schedule — just say "Schedule a morning briefing every weekday at 8am".

## Phase 9: Verify

Test the connection. Run inside a bash session:

```bash
EWS_URL="$(grep EWS_URL .env | cut -d= -f2-)" \
USERNAME="$(grep EWS_USERNAME .env | cut -d= -f2-)" \
PASSWORD="$(grep EWS_PASSWORD .env | cut -d= -f2-)" \
bash scripts/exchange/get_inbox.sh | head -50
```

If the output contains XML with `<m:FindItemResponse`, the connection is working. If you see an authentication error (401) or connection refused, check the EWS URL and credentials with the user.

## Troubleshooting

### 401 Unauthorized

- Verify the username format: Exchange often requires `DOMAIN\username` (with a backslash). In `.env` write it as `EWS_USERNAME=DOMAIN\username`.
- Confirm NTLM auth is enabled on the EWS endpoint (most on-premise Exchange servers use it by default).

### Connection refused / SSL error

- The EWS URL must include the full path ending in `/EWS/Exchange.asmx`
- For self-signed certs, add `--insecure` to the curl command in the scripts (edit `scripts/exchange/*.sh`)

### xmllint not found

- Rebuild the container: the Dockerfile change in Phase 6 installs `libxml2-utils`. Run `cd container && ./build.sh`

### Credential security

- Credentials are stored in `.env` (gitignored) and passed to the container via stdin — never as environment variables visible to subprocesses
- The agent reads them as `$EWS_URL` etc. because they are injected into the Claude SDK env, not into shell env

## Removal

1. Remove `EWS_URL`, `EWS_USERNAME`, `EWS_PASSWORD` from `.env`
2. Remove those three keys from `readSecrets()` in `src/container-runner.ts`
3. Delete `scripts/exchange/`
4. Remove `libxml2-utils \` from `container/Dockerfile`
5. Remove the "Exchange Email & Calendar" section from `groups/global/CLAUDE.md`
6. Remove `exchange-web-services` from `.nanoclaw/state.yaml`
7. Rebuild: `cd container && ./build.sh && cd .. && npm run build && systemctl --user restart nanoclaw`

---
name: paperless
description: Search and read documents from Paperless-ngx. Use when the user asks about their documents, invoices, letters, scanned files, or asks to find something in their document archive.
allowed-tools: Bash(paperless*)
---

# Paperless-ngx Document Search

Query the user's Paperless-ngx document management system to search, list, and read documents including PDFs.

## Commands

```bash
sh /home/node/.claude/skills/paperless/paperless search "invoice 2024"
sh /home/node/.claude/skills/paperless/paperless get <id>
sh /home/node/.claude/skills/paperless/paperless list [page]
sh /home/node/.claude/skills/paperless/paperless tags
sh /home/node/.claude/skills/paperless/paperless correspondents
```

## When to use

- User asks "find my invoice from X", "show me the letter about Y", "search my documents for Z"
- User asks to list or browse their document archive
- User wants to know what tags or correspondents exist
- User asks about a specific document by title or topic

## Workflow

1. **search** — start here for any topic query; returns matching doc IDs and titles
2. **get** — fetch full extracted text by ID once you know which document to read
3. **list** — browse recent documents when no specific query is given
4. **tags / correspondents** — explore the document taxonomy if useful

## Notes

- `search` uses Paperless full-text search (same engine as the web UI)
- `get` returns the OCR-extracted text content stored by Paperless — no need to download the PDF
- Results are limited to 10 for search and 20 per page for list; ask the user to refine the query if too many results are returned
- Requires `PAPERLESS_URL` and `PAPERLESS_TOKEN` to be set in `.env`

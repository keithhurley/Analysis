---
name: preparing-restart
description: Brings every project tracking file up to date before the conversation is restarted, and writes a restart brief into AGENTS.md telling the next conversation exactly what to read and do first. Use when the user says they are about to restart, start a new conversation, hand off, save context, "update all project files", or asks for a restart/handoff prompt. Works with projects that keep AGENTS.md (or DATABOT.md), PROGRESS.md and PROMPTS.md.
---

# Preparing a restart

The next conversation starts with no memory except the project memory file (`AGENTS.md` or
`DATABOT.md` in the project root), which is injected automatically. Everything the next
session needs must therefore be either in that file or pointed to by it. The goal is a
handoff that a fresh session can act on after reading one short section.

Copy this checklist into the response and tick items off:

```
Restart prep:
- [ ] 1. Log this prompt in PROMPTS.md
- [ ] 2. Gather state (git, conversation, open items)
- [ ] 3. Bring PROGRESS.md up to date
- [ ] 4. Bring AGENTS.md up to date (build state, baseline, stale claims)
- [ ] 5. Replace the restart brief at the top of AGENTS.md
- [ ] 6. Verify the edits
- [ ] 7. Ask about commit/push
- [ ] 8. Give the user the opening prompt
```

## Rules

- **Record, don't reinterpret.** Carry decisions, findings and open questions forward as they were
  made. Never delete or renumber existing entries; mark closed items closed.
- **Never change analysis code, data, or rendered outputs** as part of this skill. Only the tracking
  files are edited.
- **Read only what is needed**: the head of AGENTS.md, the tail of PROGRESS.md and PROMPTS.md, and
  `git log` / `git status`. Do not reread whole large files.
- **Anything unverified is labelled unverified** (e.g. "rendered but not checked in Word").
- Do not commit or push without asking, unless the user's request already said to.
- If a tracking file is missing, say so and ask before creating it.

## Step 2: Gather state

```bash
git status --short
git log --oneline -10
```

From the conversation, list:
- work done since the last PROGRESS.md entry (decisions, findings, verification numbers);
- anything half-finished or rendered but not checked;
- open questions awaiting the user;
- environment facts a new session would otherwise rediscover (packages installed, helpers that
  exist only in the console, locked files, long render times).

## Step 3: PROGRESS.md

Append one dated section for work not yet recorded, following the file's existing numbering
(next D#, F#, Q#) and table formats. End it with the current open-questions list, so the newest
section always holds the complete list of what is open.

## Step 4: AGENTS.md body

Update only facts that changed: build/status table, verification baseline, file list, and any
statement the session showed to be wrong or stale. Keep edits minimal and in the file's style.

## Step 5: The restart brief

Insert, or **replace in full** if one exists, a section directly below the file's title block,
between these markers, so there is only ever one brief:

```markdown
<!-- RESTART-BRIEF:START -->
## 0. Start here (restart brief, YYYY-MM-DD)

**Last commit:** `<hash>` <message> — working tree <clean | N uncommitted files: ...>
**Where we are:** <one or two sentences: current step/chapter and its state>

**Read before doing anything** (in this order, only these):
1. This file, sections <list the ones that matter now>.
2. `PROGRESS.md` from the heading "<exact heading>" (line ~N) to the end.
3. <any other file/section the next task needs, with line ranges>

**Open questions for the user:** <Q# — one line each, or "none">
**Unverified / pending:** <items, or "none">
**Environment notes:** <e.g. packages installed; helpers not saved to files; close Word before rendering>

**First action in the new conversation:** <exactly what to do, e.g. "confirm the brief with the user, then ask which open question to take first">
<!-- RESTART-BRIEF:END -->
```

Keep the brief under ~30 lines. It points to detail; it does not repeat it.

## Step 6: Verify

- Re-read the brief and the new PROGRESS.md section as written.
- Check the numbering continues without gaps or duplicates (e.g. `grep -n "^| D1[0-9][0-9] |" PROGRESS.md`).
- Check the line numbers cited in the brief point at the right headings.
- Check each brief marker appears exactly once.

## Step 8: Opening prompt

End the reply with a short prompt the user can paste into the new conversation, for example:

```text
New conversation for <project>. Read the "0. Start here" restart brief in AGENTS.md and the
PROGRESS.md section it points to, then summarise where we are and list the open questions.
Don't change any files until I say so.
```

Also say whether restarting now makes sense (a long conversation or a natural break point) or
whether finishing the current item first would be better.

# specs/ — conventions

This project uses Eric's spec-driven workflow (see
`~/.claude/spec-kit-playbook.md`). All non-trivial work is specified
before it's built.

## Read first

In any new Claude session on this project, in this order:

1. [constitution.md](constitution.md) — project invariants (license,
   stack, target environments). Immutable.
2. [current-state.md](current-state.md) — phases shipped vs. open,
   tech debt, sandbox VMID/IPs. Updated at end of each session.
3. [handoff.md](handoff.md) — what the next session should do.
   Always-current; one concrete next move.
4. The `spec.md` + `plan.md` + `tasks.md` of the phase being worked.
5. Any recent `security/audit-YYYY-MM-DD.md` for unresolved findings.

## Status table

| Phase | Description | Status |
|---|---|---|
| **phase-01** | Baseline validate on FreePBX 16 sandbox (friend-match) | 🟡 In progress |
| **phase-02** | Baseline validate on FreePBX 17 sandbox (latest) | ⏸ Pending phase-01 |
| **phase-03** | Forward-port module to FreePBX 17 | ⏸ Pending phase-02 |
| **phase-04** | Ship to friend's PBX | ⏸ Pending phase-01 |

(Keep this table in sync with [current-state.md](current-state.md) —
they should never drift.)

## Directory layout

```
specs/
  README.md            ← this file (conventions)
  constitution.md      ← project invariants — read FIRST
  current-state.md     ← refreshed at end of every session
  handoff.md           ← what to start on next; always current

  phase-01-fpbx16-validate/
    spec.md            ← user stories + acceptance criteria
    plan.md            ← architecture / approach
    tasks.md           ← ordered atomic task list
    setup-log.md       ← operational record (commands run, configs)
    findings.md        ← what the validation revealed (created during exec)

  phase-02-fpbx17-validate/   (mirrors phase-01)
  phase-NN-...                (added as planned)

  security/
    audit-YYYY-MM-DD.md   ← per-audit dated record; never edit historical
```

## End-of-session checklist

Before resetting / closing the session:

1. Run `/spec-update` (if configured) to diff git history against
   the spec docs and propose edits.
2. Update `current-state.md` with refreshed phase status, sandbox IPs
   (once known), test counts, etc.
3. Update the status table in this README to match.
4. Update `handoff.md` — keep prior open follow-ups; pick ONE concrete
   next move; group new follow-ups by phase.
5. For any phase that shipped this session, ensure its phase directory
   has `setup-log.md` (operational record so future-you can redeploy
   without re-deriving).
6. For changes that diverged from `plan.md`, add a `changes.md` in the
   phase directory rather than rewriting the spec (specs are the
   historical record once shipped).

## License + attribution reminders

Per [constitution.md §1](constitution.md):

- Project is **AGPL-3.0-only**. Don't relicense, don't strip headers.
- Eric's `/release` slash command defaults to Apache-2.0 — must
  override for this project.
- All modifications must be documented (AGPL §5(a)) — see
  [CHANGES.md](../CHANGES.md).
- DCO sign-off required on commits (`git commit -s`).
- No "Co-Authored-By: Claude" trailers.

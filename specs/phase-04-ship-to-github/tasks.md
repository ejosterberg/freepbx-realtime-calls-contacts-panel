# Phase 04 — Ship to GitHub

## Pre-flight check

- [ ] phase-01 acceptance criteria all met (module works on FreePBX 16)
- [ ] phase-02 acceptance criteria all met (module works on FreePBX 17)
- [ ] phase-03 forward-port changes applied + tested on both sandboxes
- [ ] No stale `Untracked files` that contain secrets or experiments

## Commits (logical, in order)

Each commit gets `git commit -s` (DCO sign-off). NO Co-Authored-By
trailers per Eric's convention.

1. **`chore: license consistency fixes per AGPL §5(a)`**
   - `calls-contacts-panel/package.json` MIT → AGPL-3.0-only
   - `calls-contacts-panel/frontend/package.json` add license field
   - `CHANGES.md` (new file)

2. **`docs: add specs/ for spec-driven workflow`**
   - All of `specs/` (constitution, current-state, handoff, phases)

3. **`feat: FreePBX 17 compatibility — module API + install path`**
   - `module.xml` — v17.0.0, dual-version supported, publisher
   - `Callpanel.class.php` — Node 18+ min, install builds backend + frontend
   - `Callpanel.class.php` — PHP 8 null-safety, strict CSRF compare
   - `views/main.php` — PHP 8 null-safety
   - `calls-contacts-panel/package.json` — Node 18+ engines

4. **`docs: README — fork notice, compat table, install steps`**
   - `README.md`

5. **`ci: GitHub Actions release workflow — build tarball on tag push`**
   - `.github/workflows/release.yml`

## Push

```
git push origin main
```

## Tag + Release

```
git tag -a v17.0.0 -m "v17.0.0 — FreePBX 17 compatibility + install build fix"
git push origin v17.0.0
```

The GHA workflow auto-fires on the tag push and creates the GitHub
release with the module tarball attached. Verify:

```
gh release view v17.0.0
gh release download v17.0.0 --pattern '*.tgz' -O /tmp/ship-test.tgz
tar -tzf /tmp/ship-test.tgz | head -10  # sanity check
```

## Post-ship

- [ ] Verify the release URL works for FreePBX Module Admin "Upload
      Modules → Download from URL"
- [ ] Email friend with the tarball link + install instructions
- [ ] Update `specs/current-state.md` to mark phase-04 complete
- [ ] Update `specs/handoff.md` with the deferred follow-ups (phase-05+
      modernization items from constitution §4)

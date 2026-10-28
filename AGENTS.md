# Repository instructions

These instructions apply to the entire repository.

## Scope

This branch supports Majestic Launcher 6.3.4 with GTA V Legacy through Proton.
Do not claim compatibility with another launcher version until the exact
official build has passed extraction, patching, repacking, syntax, and
idempotency checks.

## Safety requirements

- Never commit Windows executables, game files, launcher archives, extracted
  `app.asar` contents, logs, cookies, tokens, or account data.
- Never add a third-party repacked launcher or executable download. The
  official Majestic CDN may only be used after an explicit interactive choice
  or a non-interactive `--download` flag. Never download silently.
- Do not add automatic deletion or relocation of GTA files. Destructive cleanup
  must enumerate exact targets and require explicit confirmation.
- Do not use `shell=True`, `eval`, or unvalidated shell fragments.
- Keep generated config portable: no usernames, home directories, machine
  paths, GPU models, or other host-specific values.
- Keep optional integrations out of the default execution path.

## Patcher invariants

- Match a narrow semantic anchor, not an arbitrary minified variable name.
- Preserve the minifier-selected local variable when injecting code.
- Fail closed if a required anchor is missing.
- Write a backup before replacing `app.asar`.
- Every patch must be idempotent and have one stable marker.
- The Launcher 6.3.4 markers are:
  - `MAJESTIC_PROTON_UPDATER_DISABLED_V1`
  - `MAJESTIC_PROTON_MODERN_INSTALL_V2`
  - `MAJESTIC_PROTON_PATCH_V2`

## Required validation

Run before committing:

```bash
python3 -m compileall -q majestic_linux
python3 -m unittest discover -s tests -v
bash -n install-and-run-majestic-proton.sh packaging/*.sh
git diff --check
```

When changing packaging, keep `packaging/asar/package-lock.json` reproducible,
inspect package contents, and smoke-test the AppImage with
`APPIMAGE_EXTRACT_AND_RUN=1 ... setup --help`. Branch builds must upload Actions
artifacts; only `v*` tags may create a GitHub Release.

For a new supported launcher build, also test against an isolated copy of the
official installer without executing it:

1. extract the installer and `app.asar`;
2. apply the patch once and verify all expected markers;
3. run `node --check` on modified JavaScript files;
4. apply the patch a second time and verify `changed=False`;
5. confirm `app.asar.bak` matches the original archive.

## Documentation

Update README compatibility statements, known limitations, version metadata,
and tests together. Prefer generic examples and auto-detection. Any manual path
example must use placeholders rather than a real user's filesystem.

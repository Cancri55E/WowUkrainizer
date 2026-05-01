# Release Process

Two-step, PR-gated release flow.

## Workflows

| File                              | Trigger                                          | Purpose                                                                  |
| --------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------ |
| `release-prepare.yml`             | Manual dispatch (input: `version`)               | Cut release branch, finalize changelogs, regen DB, build artifact, open draft PR |
| `release-publish.yml`             | `pull_request: closed` on `master` from `release/v*` (merged only) | Tag, GitHub Release, CurseForge upload, merge back to develop, delete branch |
| `package.yml`                     | Manual dispatch / called by the two above        | Builds the addon zip; uploads to CF and/or GitHub release based on inputs |
| `sync-database.yml`               | Manual dispatch                                  | Refresh `Database/` on `develop` between releases (independent)          |

## Step 1 — Prepare

Run **Actions → Release - Prepare → Run workflow** with `version` = `X.Y.Z`.

What it does:

1. Validates `version` matches `^[0-9]+\.[0-9]+\.[0-9]+$`.
2. Checks `develop` for `* **[Next]:**` in `CHANGELOG.md` and `version = "Next"` in `Database/Init.lua`. Fails fast if missing.
3. Verifies `release/v<version>` does not already exist on origin.
4. Creates branch `release/v<version>` from `develop`.
5. Finalizes changelogs on the branch:
   - `CHANGELOG.md`: `* **[Next]:**` → `* **v<version> (YYYY-MM-DD):**`.
   - `Database/Init.lua`: `version = "Next"` → `version = "<version>"`; first `date = ""` → Ukrainian-formatted date (e.g. `28 квітня 2026`).
6. Regenerates `Database/` via DevTools (only place this happens).
7. Commits `chore: prepare release v<version>`, pushes the branch.
8. Dispatches `package.yml` against the branch with `publish_to_curseforge=false`, `create_github_release=false`, `version_override=<version>` → produces a zip artifact (`WowUkrainizer-v<version>.<translation_build>`, 30-day retention).
9. Opens a **draft** PR `release/v<version> → master` with a checklist.

After Step 1 you can:
- Pull the artifact from the package run, install it, smoke-test in WoW.
- Push hotfixes directly to `release/v<version>`.
- Re-dispatch `package.yml` against the branch as many times as needed (artifact-only, see "Re-running artifact builds" below).
- When happy, mark the PR ready and merge.

## Step 2 — Publish

Triggered automatically when the draft PR is **merged** into `master`.

What it does:

1. Extracts version from the head branch (`release/v<version>` → `<version>`).
2. Checks out `master` (now contains the merged changes).
3. Sanity-checks no `[Next]` markers leaked into master.
4. Computes `FULL_VERSION = v<version>.<RawData commit count>`.
5. Tags the merge commit with `<FULL_VERSION>` and pushes (skipped idempotently if the tag already exists).
6. Extracts release notes from `CHANGELOG.md` for the `v<version>` block.
7. Creates the GitHub Release.
8. Dispatches `package.yml` against the tag with `publish_to_curseforge=true`, `create_github_release=true` (uploads zip to the release and to CurseForge).
9. Merges `master` back into `develop` and pushes (warns and aborts on conflict — manual merge required).
10. Deletes the `release/v<version>` branch on origin.

## Re-running artifact builds (Step 1)

To rebuild the artifact for a release branch after pushing fixes:

**Actions → Build and Deploy Package → Run workflow**, `Use workflow from: release/v<version>`, with:
- `publish_to_curseforge` = `false`
- `create_github_release` = `false`
- `version_override` = `<version>`

`version_override` is required when running against a branch — the workflow has no tag to derive the base version from.

## CurseForge re-upload after a Step 2 failure

If Step 2 finishes but CurseForge upload fails, the tag and GitHub Release already exist. Recovery:

**Actions → Build and Deploy Package → Run workflow**, `Use workflow from: <FULL_VERSION>` tag, with:
- `publish_to_curseforge` = `true`
- `create_github_release` = `false`
- `version_override` left empty (tag-derived)

CurseForge accepts re-uploads for a version (creates a new file). The GitHub release stays untouched.

## Versioning

| Identifier         | Source                                                              | Example          |
| ------------------ | ------------------------------------------------------------------- | ---------------- |
| `version`          | Step 1 input (`X.Y.Z`)                                              | `1.16.0`         |
| translation build  | `git rev-list --count HEAD` in `WowUkrainizer-Data`                 | `4231`           |
| `FULL_VERSION`     | `v<version>.<translation_build>` — git tag and TOC version          | `v1.16.0.4231`   |
| Release name       | `v<version>`                                                        | `v1.16.0`        |

## Required secrets

- `REPO_ACCESS_TOKEN` — push to this repo (branches, tags, develop), check out sibling repos (`WowUkrainizer-DevTools`, `WowUkrainizer-Data`), dispatch workflows via API, open PRs.
- `MAIN_DB_CONNECTION_STRING`, `MONGODB_CONNECTION_STRING` — DevTools `generate-lua` inputs (Step 1 + manual `package.yml`).
- `CF_API_KEY` — CurseForge upload (used when `publish_to_curseforge=true`).
- `GITHUB_TOKEN` — auto-provided; attaches the zip to the GitHub Release.

## Bootstrap note

`release-publish.yml` triggers on PRs into `master`. GitHub reads workflow files for `pull_request` events from the **default branch (`master`)**, so this file must exist on `master` before the first release. Merge it in directly the first time.

## Failure modes

- **Missing `[Next]` section** — add to `develop` before re-running Step 1.
- **Branch already exists** — delete `release/v<version>` or pick a different version.
- **Auto-merge to develop fails (Step 2)** — workflow warns and continues. Resolve manually:
  ```sh
  git checkout develop
  git merge origin/master
  git push origin develop
  ```
- **CurseForge upload fails (Step 2)** — see "CurseForge re-upload" above.
- **Tag already exists (Step 2)** — skipped idempotently. Safe to re-run by re-merging or by manually dispatching `package.yml` against the tag.

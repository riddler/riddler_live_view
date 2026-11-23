# Release extension

Additional required steps for `/wurk:release` in this repo. The skill reads
this file before step 1 of its `kind: "hex"` recipe and treats what is here as
required steps placed where this file says. Extensions add; they never
override.

## The package is at 0.0.0 until its release prep

`mix.exs` carries `@version "0.0.0"`. The first release is cut by hand, as a
diff a reviewer reads, through the "At release" section of
[`changelog.d/README.md`](../../changelog.d/README.md): the version bump, the
README install pin and the changelog promotion. Every release after the first
is an ordinary `/wurk:release` run with the promotion step below.

## Why the recipe names no changelog

`changelog.mode` is `fragments`: `CHANGELOG.md` has no `## [Unreleased]`
heading and never will, so `release.changelog` is deliberately absent.

## The required step: promote the changelog fragments

1. Read every `changelog.d/*.md` fragment except `README.md`. If there is none,
   there is nothing to release and the run stops.
2. Insert a new `## [X.Y.Z] YYYY-MM-DD` section into `CHANGELOG.md` directly
   under the file's header paragraphs, or above the previous version's
   section. The date is the operator's local date from `date +%F`, not UTC.
3. Write a short lead paragraph, then the fragments' bullets grouped by
   heading and ordered `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`,
   `Security`, carrying every bullet over byte for byte; fragments within one
   heading go in fragment-name order.
4. Delete the promoted fragment files in the same commit. `README.md` stays.

## The README install pin: write the `.0` form

`README.md` carries a `{:riddler_live_view, "~> X.Y.0"}` pin in its `def deps`
snippet. A release writes the exact minor it cuts, patch component `0`
included, and a prep that finds the skill has written `~> X.Y` restores the
`.0`.

## The files a release commit touches

| File | Moved by |
|---|---|
| `mix.exs` | the recipe's `version_file` |
| `README.md` | the recipe's `readme_pin` |
| `CHANGELOG.md` | the promotion step |
| `changelog.d/*.md` (deleted) | the promotion step |

## What a release here still is not

The skill does not tag, push, open a request or publish, and this extension
does not either. Once the prep is merged to `origin/main`, the conductor or the
session that owns the release bead tags the merged commit and pushes the tag.
An agent or a session never runs `mix hex.publish` and never reads or sets a
secret: the release workflow publishes on the tag push, and a failed workflow
is re-run from its Actions page, never worked round by a local publish.

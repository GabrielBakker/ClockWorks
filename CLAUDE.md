# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A new **Business Rules! (BR)** application, built from scratch on the owner's (Gabriel Bakker's)
standard toolset: **Lexi** (source preprocessor), **FileIO** (data-file access) and **ScreenIO**
(screens). It is not a web or npm/node project: there is no `package.json`, build script, or
conventional test runner. Source is `.brs` (BR Business BASIC), compiled to tokenized `.br`, run
inside the BR runtime.

The folder started with only BR, FileIO and ScreenIO installed. **There is no application code
yet.** Claude writes the app, starting with its own **`start.brs`**, the program that launches it.

**Read `context/README.md` before making any changes.** It is the entry point for a full context
kit covering BR language semantics, coding conventions, and the ScreenIO internals. Everything
below is a quick-reference summary; the kit has the depth and the authoritative detail.

## Development commands

There is no build/lint/test command in the conventional sense. BR's equivalents:

```powershell
# Environment (see context/dev/BR_launch.md for the full picture)
$env:BR_EXE     = "context\dev\tools\brserver-433c-Win32-Debug-2026-08-27.exe"
$env:BR_AI_UTIL = "context\dev\tools\brconfig.ai_util"   # headless/unattended
$env:BRLS_EXE   = "context\dev\tools\brls.exe"            # standalone syntax checker, no BR needed

# Translate Lexi source to plain BR (and optionally compile it)
context\dev\tools\lexi-compile.ps1 -Source somefile.brs -OutFile somefile.plain.brs [-Compile]

# Fast syntax pre-check, run on the Lexi-TRANSLATED output, not the raw source
& $env:BRLS_EXE -check -sema somefile.plain.brs

# Authoritative compile-check (parses, reports first error + line)
& $env:BR_EXE "LOAD somefile.brs source" -$env:BR_AI_UTIL
```

**Source here is written for Lexi**, a BR preprocessor written by the app owner. It adds syntax that
base BR and `brls` don't understand (`/* */` comments, `X$&=`, `#Select#/#Case#/#End Select#`,
`#Autonumber#`). A `brls`/`LOAD` failure on that syntax is not a real bug; use the Lexi-aware
coding loop in `context/dev/APP-DEV-GUIDE.md` §6.1. Saving a `.brs` in VS Code with the "BR
Language Server" extension (`crs-dev.vslang-br`) installed runs Lexi automatically.

## Architecture — quick orientation

House style is in `context/app/conventions.md` (always-load). The short version:

- **Entry point:** `start.brs` (to be written) launches the app. From there, screens run through
  ScreenIO (`library "screenio" : fnfm$`/`fnfm`).
- **`function/`** holds the real, hand-edited source for ScreenIO event code and shared helpers,
  one function per file. It already holds ScreenIO's stock functions (listview add/delete, CSV
  export, print listview, etc.).
- **`screenio/`** holds *generated* ScreenIO Helper Libraries stitched from `function/` at
  screen-compile time (through Lexi). Never hand-edit files there; edit the `function/` source and
  recompile the screen.
- **`Screen/`** holds ScreenIO's screen definitions (`screenio.dat`/`screenfld.dat`). These are
  binary; change them only through ScreenIO or FileIO code (see `context/dev/screenio-guide.md`
  §9), never by hand.
- **`FileLay/`** is the data dictionary (one `.lay` file per data file; `template/` holds starter
  layouts). **`Data/`** holds runtime data and is empty to start. When a data file is added, run
  ONBOARDING STEP 4 to regenerate `context/app/data-model.md`, and check it for a file's real
  fields/keys before writing `OPEN`/`READ`/`KEY=` code. Never guess a layout.
- File access goes through the **FileIO** library (`fnOpenFile`, usually via a local `fnopen`
  wrapper). Raw keyed `OPEN`/`KFNAME=` is reserved for the rare case FileIO can't cover.
- Shipped support files at the root: `fileio.brs/.br`, `screenio.brs/.br`, `lexi.brs/.br`
  (used by ScreenIO's screen compile), `run.brs` (ScreenIO run-screen / tabbed-screen library) and
  `login.brs` (a web-login library, not part of the app). BR's config is `brconfig.sys` →
  `settings.sys`, and BR starts in the app root. `brconfig.sys` launches the app with
  `execute "run start"` (added 2026-10-09 at the owner's request). The AI configs strip that line,
  so headless runs don't start the register.
- `context/app/exemplars/` and `context/app/examples/` hold ScreenIO archetypes and technique
  scripts carried over from an earlier app. Copy their shape, not their names; the data files and
  libraries they reference don't exist here.

## Git workflow: app repo vs. the template (Basic-BR-Config)

Each app is cloned from the **Basic-BR-Config** template and keeps its own history. The owner is
new to git, so Claude runs the git mechanics and explains them.

- `origin` is the app's own repo. `template` is Basic-BR-Config, **fetch only**: its push URL is
  deliberately set to `DISABLED-...`. Never re-enable it.
- App work (programs, screens, layouts, `data-model.md`, `architecture.md`, this file's app
  description) is committed only to the app repo.
- Lessons that change the **context kit** (`context/dev/`, `context/br_tree/`, `context/README.md`,
  `context/ERRORS.md`, `context/app/conventions.md`, exemplars/examples, or this git-workflow
  section) are committed **separately**, never mixed with app changes, with a message starting
  `kit:`.
- Promoting to the template happens only when the owner asks. In the template's own working copy
  (`C:\Everything\Work\Training`), `git fetch` this app's folder, `git cherry-pick` the `kit:`
  commits, show the owner the list, and push to Basic-BR-Config only after they approve.

---
title: House coding conventions
file: conventions.md
category: app
alwaysApply: true
description: The app owner's house BR coding style (Lexi, FileIO, ScreenIO). Carried over from prior onboarded work; always-load when reading or writing this app's code.
---

# House coding conventions

These are the owner's house rules for BR development. They were first derived (and
frequency-checked) from an earlier production app, and they apply to this app too.
[`exemplars/`](exemplars/README.md) keeps that app's ScreenIO archetypes (generated helper libraries
and their `function/` units). [`examples/`](examples/README.md) keeps its ScreenIO technique
scripts, such as writing screens from code. Add this app's own exemplars as they're written
(ONBOARDING STEP 5).

## 1. Source is written for Lexi, not base BR directly

`.brs` source targets the **Lexi preprocessor**, written by the app owner (Gabriel Bakker) starting
in 2003 — `lexi.brs`'s own header carries `Copyright 2003 Gabriel Bakker` /
`Copyright 2007 Sage AX, LLC and Gabriel Bakker`. Lexi was the original toolset that made
file-based source editing possible in BR at all. Two physically separate copies of it run:
`lexi.brs` at the app root — the copy **ScreenIO** invokes when compiling a screen's Helper Library
from `function/` pieces (§7) — and the copy bundled in the "BR Language Server" VS Code extension
(`crs-dev.vslang-br`), which **saving a `.brs` file in VS Code automatically invokes**, generating
the matching `.br` on save.

Lexi accepts constructs base BR (and `brls.exe`) don't, then rewrites them to plain BR — confirmed
by actually running Lexi's `fnApplyLexi` against test input, not inferred from a comment:

- `/* ... */` — multi-line comment, rewritten to ordinary `!` comments.
- `X$&="..."` — rewritten to `X$(INF:0)="..."` (the safe append idiom — **not** naive
  `X$=X$&"..."` self-concatenation).
- `#Select# expr #Case# value ... #End Select#` — real Lexi syntax (the `#` signs are required),
  translated line-for-line into `IF expr = value THEN ... ELSE IF ... END IF`, each original line
  kept as a trailing comment. **A bare `SELECT CASE ... END SELECT` (no `#`) is not valid syntax
  at all** — Lexi leaves it untouched and it then fails to compile in real BR. (`lexi.brs`'s own
  header describes the feature informally as "Select Case"; the required spelling uses
  `#Select#`/`#Case#`. See `context/ERRORS.md`, 2026-09-11.)
- Per the owner, several other "modern programming statement" conveniences beyond just these — this
  list is not exhaustive.

**Consequence:** `brls -check` does not understand Lexi and will report false-positive syntax
errors on any of the above (see `context/ERRORS.md`'s 2026-09-10 entry). Don't treat a `brls`
failure on `#Select#`/`/* */`/`&=` as evidence the source is wrong — use the Lexi-aware coding loop
in `dev/APP-DEV-GUIDE.md` §6.1.

This also applies inside `function/*.brs` files used by ScreenIO screens: ScreenIO's screen-compile
step pulls in every function a screen uses and passes the stitched result through Lexi before it
becomes the screen's helper library (§7) — so Lexi directives are just as valid in `function/`
source as anywhere else.

## 2. File access: FileIO is the house library, not raw keyed I/O

`library "fileio" : fnOpenFile`, always called through the local `Fnopen` wrapper below, is how
app code opens data files. In the reference app essentially all data
access went this way; raw keyed `OPEN ... KFNAME=` appeared only in FileIO's own implementation,
copy-paste starter templates under `FileLay/template/`, and narrow low-level helpers needing
something FileIO doesn't expose (e.g. counting records via a raw `RELATIVE` open).

**Rule:** use FileIO for all data file access in app code, and **always open files through the
local `Fnopen` wrapper — never call `fnOpenFile` directly** (owner's rule, 2026-10-09). The
wrapper is copied into each program verbatim:

```
OPEN: ! ***** Function To Call Library Openfile And Proc Subs  #Autonumber# 99000,10
   def Fnopen(Filename$*255, Mat F$, Mat F, Mat Form$; Inputonly, Keynum, Dont_Sort_Subs, Path$*255, Mat Descr$, Mat Field_Widths,Supress_Prompt,Ignore_Errors,Suppress_Log,mat DateFmt$,___,Index)
      dim _FileIOSubs$(1)*800, _Loadedsubs$(1)*80
      let Fnopen=Fnopenfile(Filename$, Mat F$, Mat F, Mat Form$, Inputonly, Keynum, Dont_Sort_Subs, Path$, Mat Descr$, Mat Field_Widths, Mat _FileIOSubs$, Supress_Prompt,Ignore_Errors,Program$,Suppress_Log,mat DateFmt$)
      if Srch(_Loadedsubs$,Uprc$(Filename$))<=0 then : mat _Loadedsubs$(Udim(_Loadedsubs$)+1) : let _Loadedsubs$(Udim(_Loadedsubs$))=Uprc$(Filename$) : for Index=1 to Udim(Mat _Fileiosubs$) : execute (_Fileiosubs$(Index)) : next Index
   fnend
```

It executes the subscript assignments FileIO returns (`IN_ITEMID`, ...) exactly once per layout,
and it passes every by-reference argument as a variable. Calling `fnOpenFile` directly with a
literal such as `""` for `Path$` fails with BR error 0303, "cannot pass a literal by reference". Raw keyed `OPEN`/`KFNAME=` is reserved for the rare utility that needs
file-level access FileIO doesn't provide — it is not a normal alternative for reading app data.

**Layout version numbers** (owner's convention, 2026-10-09): a layout's header version is `0` only
for a legacy file written without FileIO, whose layout was added later. Never change a version-0
layout, because other programs may read that file with their own `FORM`s. **Every new file starts
at version `1`**, meaning it is always accessed through FileIO, and each layout change bumps it by
one. Full rule: ONBOARDING Appendix A.

## 3. Error handling: trailing I/O clauses, not ON ERROR handlers

Use BR's own trailing error clauses on the I/O statement itself — `NOKEY`, `EOF ... IGNORE`,
`ERROR ... IGNORE` — rather than a global `ON ERROR GOTO` handler (rare in house code). Handle
`EOF`/`NOKEY`/`IOERR`/`LOCKED` inline on the statement that can raise them, e.g.
`LINPUT #TextFile: Line$ EOF IGNORE`.

User-facing errors go through `Msgbox` with a plain-language, conversational message rather than a
raw error code.

**Prefer block `IF … END IF` whenever a branch holds more than one statement** (owner's
preference, for readability). BR does run every `:`-separated statement after a one-line `THEN`
under the condition (see `dev/essentials.md`), so the one-line form isn't wrong, just harder to
read.

## 4. Library-file idiom: run-guard + linkage-established-once

Shared library files (root `*lib.brs`) commonly open with a guard that makes accidentally `RUN`ning
the library fail loudly instead of silently doing nothing:

```
print "This is a library and cannot be run directly." : stop
```

(Common, not universal: a file that doubles as both a runnable entry point and a library puts real
driver code before the `stop` instead.)

Cross-library dependencies are wired up through a one-time linkage helper — some spelling of
`fnLibraryLinkage`/`fnEstablishLibraryLinkage`, guarded by a flag variable so the `library "x" :
fn...` statements only execute once per run.

## 5. Naming

- **Subscript constants** are `<lowercased file-prefix>_<fieldname>`, matching each data file's
  `FileLay/` prefix column lowercased — e.g. a layout with prefix `CU_` gives `cu_code`,
  `cu_name`. The authoritative prefix-to-file mapping is `app/data-model.md` (generated from
  `FileLay/`, ONBOARDING STEP 4); don't guess a prefix, look it up there.
- **ScreenIO's own passed-field subscripts** (the `mat s$`/`mat S$` argument every screen event
  function receives) use a separate convention not tied to any one data file — e.g.
  `sio_startdate`/`sio_enddate`. Treat it as a ScreenIO library detail
  (`br_tree/50-libraries/screenio/`, `dev/screenio-guide.md`), not part of the file-prefix scheme.
- **Program name suffixes** signal role: `*edit`/`*list`/`*select` under `screenio/` are ScreenIO
  form archetypes (maintenance form, browse list, pick-list respectively); `*lib` at the root is a
  shared multi-function library; entry points carry no suffix. Function names under `function/`
  are verb phrases in `lowercase` with no separators (`initializeunique.brs`,
  `deletelistviewrecord.brs`) matching the one `fn...` they define.

## 6. Module placement

| Location | What lives there |
|---|---|
| app root | Entry/bootstrap programs and shared multi-function libraries, one per subject-matter domain (`*lib.brs`) |
| `function/` | **The real, hand-edited source** for ScreenIO event code and shared helpers — one function per file (§7) |
| `screenio/` | **Generated** per-screen helper libraries — never hand-edit these (§7) |
| `FileLay/` | The data dictionary (`.lay` files, one per data file, in ONBOARDING Appendix A format), plus `template/` (starter layouts to copy from) and `archive/` (superseded layouts) |
| `Data/` | The actual runtime `.dat`/key files — not source |

Keep scratch/debug/test programs out of the root, or clearly named, so they aren't mistaken for
maintained app code. When in doubt whether a root file is real, check whether anything else in the
app actually calls it.

## 7. Screen conventions — `function/` is the source, `screenio/` holds generated "ScreenIO Helper Libraries"

**For the generic mechanics** (the compile pipeline, the 8-deep nested-screen linkage, and how
event code gets names like `cu_code`/`sio_fieldname`/`ctl_fieldname` with no visible `DIM`), see
[`../dev/screenio-guide.md`](../dev/screenio-guide.md).

When a screen is compiled in ScreenIO, it pulls in every `function/<name>.brs` file the screen
actually uses, stitches their current text together, passes the result through **Lexi** (§1), and
writes out a **"ScreenIO Helper Library"** under `screenio/<screen>.brs` (the generated file headers
itself "ScreenIO Generated Helper Library for `<SCREEN>` screen"). Each imported block is tagged
`! Imported From "function\<name>.brs"`, and the whole file carries a `! Compiled On: <date>` /
`! Version: <n>` stamp. **ScreenIO also assigns the file's line numbers** — they are never
hand-maintained.

**Runtime model:** ScreenIO itself draws and drives the form (from the binary
`screenio.dat`/`screenfld.dat` definitions); the helper library is not a top-to-bottom driver
program. ScreenIO calls into it in response to user actions — a button click, a listview needing
its data, a field's validation firing — dispatched through the helper library's
`fnFunctionSwitch`/`fnFunctionSwitch$` entry points. The `Main:` block at the top
(`library "screenio" : fnfm$` / `fnfm`, screen name as first argument) exists so the screen can
also be opened directly as if it were a program; other programs open screens the same way.

**Rule:** to change a screen's behavior, edit the relevant `function/<name>.brs` file (or add a
new one) and recompile the *screen* in ScreenIO — never hand-edit `screenio/<screen>.brs`
directly; it is overwritten the next time the screen is recompiled, exactly like editing
`app/data-model.md` instead of `FileLay/`. See `exemplars/screenio_airlinesedit.brs`'s header for
the generated side and `exemplars/function_*.brs` for the editable unit.

**A function in `function/` with zero callers across every screen is not automatically a finding.**
ScreenIO itself ships with example functions and no screens to go with them, so a `function/`
folder normally carries some orphaned files. Before reporting an apparently-unused function as dead
code or a defect, check whether it's actually referenced (e.g. via ScreenIO's own Power Search).

### Modifying ScreenIO itself — `design.brs` → `design.br` → `screenio.br`

Only relevant where ScreenIO's own source, `design.brs`, is present (it is **not** in this app,
which ships the compiled `screenio.br`). **`design.brs` is ScreenIO's real, editable source** —
`screenio.brs`/`screenio.br` are its compiled, source-stripped deployment form, produced by:

1. Edit `design.brs` directly (Lexi-authored, §1). Bump `def fnVersion=<N.NN>` (in its first ~20
   lines) and prepend a matching entry to **`recentChanges.txt`** — newest-first, format
   `Version <N.NN> -- <description>.`
2. Run the Lexi-aware coding loop on `design.brs`, then `lexi-compile.ps1 -Source design.brs
   -Compile` to produce `design.br` — a *full* build including the Designer UI.
3. **`design.br` is not the deployed file.** The **`prot`** procedure (no extension) strips the
   Designer-UI source for copy protection and writes the deployment target:
   ```
   lo design
   del 71000 74999 source
   del 70400 source
   del 25500 source
   del 13040 source
   rep screenio.br
   ```
   Run it with `"$BR_EXE" "PROC prot" -"$BR_AI_UTIL"`. **`DEL ... source` does not remove
   functionality** — it only hides that range's source text from future `LIST`; the compiled code
   stays present and callable. New code outside those ranges survives intact. (A physical
   `design.brs` line position is not its BR line number — see the `#Autonumber#` caveat in
   `dev/screenio-guide.md` §9; check via the Lexi-translated output.)
4. `screenio.br` is what every `LIBRARY "screenio" : ...` statement resolves to. Redeploying it
   takes effect immediately for any new process.

## 8. Line numbering

Hand-authored files (root programs and `*lib.brs`, everything under `function/`) are stored
**free-form, without explicit line numbers**, relying on a `#Autonumber# <start>,<step>` directive
for Lexi to assign numbers on save/compile. `screenio/*.brs` files, being generated, carry explicit
sequential numbers (`00010`, `00020`, ...) baked in at generation time — don't renumber them by
hand; they're regenerated from `function/` anyway (§7).

## 9. Screen coloring: a called screen gets a noticeably darker (or lighter) shade than its caller

House style (the owner's, not a general BR or ScreenIO rule). When one screen opens another (a
listview's Add/Edit button, an embedded child screen, a "View X" button that calls `fnfm$`
directly, ...), the called screen's header `BGCOLOR$` should be a distinctly darker or lighter
variant of the caller's, not the identical color — the visual cue that the user has navigated into
a different screen. Apply it when authoring a new called screen; don't assume every existing pair
already follows it.

1. **Darken moderately, not drastically**, calibrated *relative to the caller's own color* — never
   by copying another pair's absolute values. Worked calibration the owner approved: caller
   `CC6600` → called `994D00` (roughly 75% brightness, same hue) — "a little bit darker than the
   listview screen, but not that much." An earlier attempt at ~25% brightness (`331100`) was too
   dark to read.
2. **When the background is dark enough to need white text, use the screen-level system color
   `FGCOLOR$="W"` (padded `"W     "`)**, not a literal `FFFFFF` — the more idiomatic BR/ScreenIO
   spelling, and it self-adapts.

Check the result via a CSV dump of `screenio.dat` (`dev/screenio-guide.md` §7's export method),
then have the owner confirm it visually.

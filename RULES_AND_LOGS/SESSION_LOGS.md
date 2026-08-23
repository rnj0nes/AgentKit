# Session Logs

Dated entries for work on the AgentKit infrastructure itself. Newest at the
bottom. See AGENTS.md for the logging rules.

## 2026-07-02

Reversed the core architecture from symlinks to physical copies. Rich reported
that symlinks did not work when he tried them before, so the kit now keeps
master files in `_AgentKit` and copies them into each new project at creation.
The tradeoff is deliberate: copies freeze at creation, so editing a master no
longer reaches existing projects, but each project is self-contained and
portable with no links to break. Chose freeze at creation over a re-sync
script, so there is no update_project.sh; refresh an existing project by
copying the changed master in by hand.

Added reveal.js slide support, built from Rich's actual deck
(`Types-of-invariance`), not from a guess. Slides use no pandoc reference doc.
The reusable parts are the revealjs YAML block and an `include-in-header` CSS
block (slide-number position, scrollable code). Content slides live in separate
`.qmd` files pulled into the control file with `{{< include >}}`. The driver
renders to `REPORTS/` and deletes the stray `REPORTS/FIGURES/` because images
are embedded.

Created `_AgentKit/templates/`: `slides_Control.qmd`, `slides_Driver.R`,
`manuscript_Control.qmd`, `manuscript_Driver.R`, `R/000-Libraries.R`,
`R/001-Environment-settings.R`, `CLAUDE.md`, `README.md`. The R starters are
stripped of the HCAP-specific data paths from the uploaded examples.

Added a `CLAUDE.md` pointer to each project because this work moves between VS
Code and Cowork. Copilot auto-loads `AGENTS.md` and
`.github/copilot-instructions.md`; Cowork does not, so `CLAUDE.md` tells the
agent to read them first.

Standardized R script naming on Rich's real convention (three-digit hyphen,
`000-Libraries.R`) rather than the underscore examples
(`010_environment-settings.R`) that had been in the workflow doc. The docs and
templates now match his practice.

Rewrote `new_project.sh` to copy instead of symlink, copy the templates, guard
the VS Code open behind `command -v code`, and stay zsh/bash compatible.
Updated `AGENTS.md`, `academic-writing-style.md`, `AgentKit_overview.md`,
`AgentKit_instructions.md`, and `VS-Code-workflow.md` for the copy model,
slides, and Cowork.

Current state and next step. The kit is revised and tested. `RethinkingClassification`
is not yet created; execution was left to Rich, who runs `new_project.sh`
himself from `~/Library/CloudStorage/Dropbox/Work`.

Data handling choices: none. No study data was touched.

Open questions.
- Whether to add a title-slide watermark image to `FIGURES/watermark.png` in
  the template, or leave that per project. Left open.
- The Codex skill's `references/style-profile.md` is now a copy, not a symlink,
  so it can drift. Re-copy the master into it by hand when the style changes.
- `quarto`, `pandoc`, and `code` reachability on the Mac is assumed, not
  verified from this session.

Approach note for future scaffold tests. Testing `new_project.sh` inside the
Cowork sandbox created files in the Dropbox mount that the sandbox then could
not delete without granting file-delete permission first. Expect to grant that
permission when cleaning up `_test_scaffold/`.

## 2026-08-17

Shipped `R_Rules.md` and `Mplus_Rules.md` to every project. `new_project.sh`
copies both into the project's `REFERENCES/`, and `AGENTS.md` gained a CODING
RULE FILES section telling the agent to read the first before writing R or QMD
and the second before Mplus work. Made them conditional rather than adding them
to the always-read list because the two total about 600 lines. Retitled
`R_Rules.md` from "R Rules for Slide Workflows" since roughly half of it applies
to any Quarto workflow; revealjs-only sections now carry a `(slides)` marker.

Found and fixed a contradiction that would have shipped to every project.
`AGENTS.md` told drivers to pass `quarto_args = c("--output-dir", "REPORTS")`
and both driver templates did it, while `R_Rules.md` section 10 said never to
pass `--output-dir` at all. Confirmed against Quarto's issue tracker that
Quarto empties the output directory before writing, so `R_Rules.md` was right.
The two documents were not arguing about the same thing: the `AGENTS.md` hint
answered how to pass an output directory, since `output_dir` is not a named
parameter of `quarto_render()`, and never addressed whether to.

Added `RENDER/` to the skeleton, which resolves that better than banning the
flag. Drivers now build into `RENDER/` with `--output-dir` and copy the result
into `REPORTS/` with the render date appended. Quarto's deletion still happens
but lands on scratch. Same-day reruns overwrite that day's file. Used
`format(Sys.Date())` rather than bare `Sys.Date()` inside `sprintf` because no
R was available in the sandbox to test the coercion. The drivers themselves are
therefore unrun: verified as copied text, not as a working render.

Merged the writing style. Seven files existed across three lineages that were
not versions of each other. A was a rules-and-checklist document, the Codex
`SKILL.md` of 21 May extended into `academic-writing-style.md` on 7 July. B was
the Codex `references/style-profile.md` of 23 May. C was the `my-writing-style`
skill of 31 July, built from measuring nine documents.

C already superseded A deliberately. It cites A by name and its Part 8 records
which of A's rules were kept and which were dropped. Checked all seven style
rules and four checklist items A gained on 7 July and found every one present
in C, two of them compressed into single lines. So A retired without loss.

B turned out to be orthogonal to both. Probed C for seven distinct B features
and found zero. B held the only copy of the audience note, the paragraph and
grant structures, the four-step statistical reporting sequence, the hedging
lists, the phrasebank, and the four before and after examples. It is now Parts
11 through 17, carried whole.

Two documented claims were false. `AgentKit_instructions.md` said
`style-profile.md` was a copy of `academic-writing-style.md` and told the reader
to re-copy the master over it. Similarity is 0.118 with no shared headings, so
following that instruction would have destroyed B entirely. And
`REFERENCES/Jones_Writing_Samples/copilot-instructions.md` claimed full parity
with the `my-writing-style` skill while sharing about 53 percent of its wording
and missing Parts 3.5, 3.6, and 9.2, which that skill names as the sections
carrying its positive requirements. Both corrected.

One rule was overruled rather than absorbed. A said "use short to moderate-length
sentences." C measures his median at 22 to 26 words with a standard deviation
above 14 and about a fifth of sentences past 35, and names capping sentence
length as the largest over-correction risk. A's rule shipped to every project
from 7 July until today. Recorded the removal in Part 8 rather than in the
header.

Built the merged file programmatically from both sources rather than retyping,
then checked that every paragraph of C and every content line of B survived.
Exactly one line did not, the superseded sentence-length rule, which was the
intent.

Trimmed the merged file twice on Rich's instruction. First the header, which
narrated the merge rather than instructing. Then eleven passages throughout
where the file explained what an earlier version had said instead of giving the
rule. Part 8 was the largest: its list of six un-banned constructions was
redundant, since all six are already stated as permitted in 5.19, 5.10, Part 6,
and 2.4. Provenance moved here, which is what this log is for.

Resolved redundancy between the merged parts. Of 82 items in the old Parts 11
through 17, 38 duplicated Parts 0 through 10. Old Parts 11 and 12 were almost
entirely duplication and are gone; four genuine additions moved to 0.2, 2.2,
5.18, and 2.1. Part 14's fuller statements on measurement, causal inference,
and relevance replaced Part 1's one-line versions, and its three worked contrast
examples moved into 5.10. SEE in 2.1 absorbed the four-step paragraph.

The grant material turned out to be triplicated rather than duplicated. Moving
it to the `grant-proposal-writing` skill was mostly a deletion, because that
skill already held the same value-claim bans and the same five-step Significance
structure. Only two items are absent there: the phrase "The proposed study
addresses this problem by" and one worked example. Both were dropped rather than
merged.

Added Part 15 for outlining, on Rich's request. He composes prose from an
outline himself and does not want the agent's phrasing reaching his final
document. That makes the phrasebanks in Parts 12 and 13 a hazard rather than a
help, so Part 15 suspends them along with 3.4, 5.13, 2.2's preference for more
words, 3.5, 3.6, and the 9.2 check. Fragments only, never a pasteable sentence.
Part 1 and Part 9.1 stay in force, and 15.3 requires citations, verbatim
numbers, marked gaps, and the provenance of each item.

Checked the grant adjunct's parity claim, which held: 0.94 word-level
similarity, 18 headings each, differing only in the deployment header. Also
confirmed the grant skill's six citations of base part numbers still resolve,
because today's additions went at the end and nothing was renumbered.

Cleaned up the copies. The Codex skill was regenerated: `style-profile.md` is
now a copy of the master with a generated-copy header, and `SKILL.md` was
rewritten to point at it rather than restate the retired rules. Deleted both
files in `Jones_Writing_Samples/`. `SAGES-assets.md` stays, because the grant
skill cites it.

Rewrote the maintenance line in Part 10. It had said "Any correction Rich makes
means this file is wrong. Offer, in one line, to save the change." Rich asked
what it meant, which was the tell. Read literally it covered factual fixes and
one-off document-specific choices, neither of which indicts the standard, and it
did not say where to save. It now distinguishes a rewrite or a phrasing
correction, which is evidence, from a factual correction or a choice he flags as
local, which is not. The same line survives in the grant skill and was left
alone.

Wrote `update-existing-projects.md` rather than `update_project.sh`. Rich chose
to run the update himself. Keeping it as documented commands rather than a
script preserves the freeze-at-creation decision from 2 July, which explicitly
rejected a re-sync script. Tested the loop against a fake two-project tree to
confirm it finds projects, creates `RENDER/`, and writes real content. Driver
files are excluded because each project renames them.

Self-check caught a reference I had just broken. Part 10 of the style file still
named `copilot-instructions-proposals.md` as the grant adjunct, minutes after
deleting that file. Fixed, and the Codex copy refreshed afterward so master and
copy did not diverge on their first day. The lesson generalizes: after deleting
a file, grep the kit for its name rather than assuming nothing pointed at it.

Restructured the project layout on Rich's instruction. Drivers and control
files move from the project root into `R/<Analysis>/`, one folder per analysis,
each self-contained with its own copies of the R starters. `Stata/<Analysis>/`
mirrors it. `RENDER/` and `REPORTS/` stay flat at the root with no matching
subfolders, shared by every analysis.

That structure forced abandoning `--output-dir` entirely, hours after adopting
it. With `RENDER/` flat and shared, Quarto emptying its output directory means
rendering Project2 would destroy Project1's build output. The same bug we fixed
for `REPORTS/` this morning, one level down. Drivers now render beside their
control file, move the result into `RENDER/`, and copy a dated version into
`REPORTS/`. No driver passes a destructive flag any more.

Flat output folders make filename collision the default rather than an edge
case, so driver output carries the analysis name as a prefix, built from an
`analysis` variable the driver already needs. `Project1_manuscript_2026-08-17.docx`.

Chose per-analysis copies of the R starters over a shared pair at the `R/`
level. Rich's call. It accepts drift between analyses in exchange for each
analysis folder being self-contained, which matches the copy-on-creation model
the kit already uses for projects.

Testing caught a defect that reading would not have. Every path in the new
drivers runs through `here::here()`, and the scaffold created no root marker,
so `here()` would have fallen back to the working directory and resolved every
path to the wrong place, silently. `new_project.sh` now writes a `.here` file,
and both `AGENTS.md` and `R_Rules.md` say not to delete it. This is the second
time this session that running the thing found what reading it did not.

YAML paths are the one place the no-absolute-paths invariant bends. A control
file in `R/<Analysis>/` reaches the project root with `../../` for
`reference-doc`, `bibliography`, and the slide watermark, because YAML cannot
call `here::here()`. Documented as an explicit exception rather than left to be
rediscovered.

Left `R/RDATA/` and `R/MPLUS_OUTPUT/` flat as siblings of the analysis folders
rather than moving them inside each analysis. Raised with Rich as an open
collision risk, since two analyses writing the same intermediate name would
overwrite each other, and he accepted the current arrangement. Section 4 figure
naming in `R_Rules.md` is the existing convention that keeps this manageable.

Fixed one straggler the layout sweep missed. The R driver example in section 1.4
of `VS-Code-workflow.md` still rendered a control file from the project root.
Found it by grepping the whole kit for root-relative driver patterns rather than
by reading, which is how the earlier stale-reference bug was found too.

Moved the pandoc reference documents out of the project root into a project
`TEMPLATES/` folder, and the kit's own copies into `_AgentKit/templates/`
alongside the other starter files. The root was left holding three binary build
assets beside the files a person actually reads, which is the same argument that
moved drivers and control files out of the root earlier in the session.

Rich supplied a fact that changed the reasoning. These documents are restyled
per project, often more than once, so they are working files rather than shared
constants. That makes copy-at-creation right for them rather than merely
tolerable, and it makes a dedicated folder more useful than it would otherwise
be. It also creates a risk worth naming: rebuilding a reference document from a
real manuscript brings that manuscript's text, citation keys, and cited DOIs
back into the file, invisible in Word and ignored by pandoc. `AGENTS.md` and the
project README now say to run `scrub_reference_docs.py` before sharing a project.

Fourteen files referenced the old location. Verified the move by scaffolding and
then rendering with pandoc through the relative path exactly as the control file
YAML writes it, `../../TEMPLATES/reference_manuscript.docx`, rather than trusting
that the file had landed somewhere plausible.

The sweep found more stragglers from the afternoon's restructure than from this
change. `templates/README.md` still carried a whole section describing the old
root layout, listing drivers and control files at the project root and telling
the reader to render from there; it ships to every project, so it was rewritten
rather than patched. `VS-Code-workflow.md` section 1.2 still said to create one
project level driver and run it from the root, and an appendix still showed a
`reference-doc` path with no `../../`. Grepping for the thing being changed
keeps surfacing unrelated staleness, which is an argument for grepping the whole
kit after any structural change rather than only the files expected to move.

Split `REFERENCES/` into two folders. It had accumulated five kinds of thing:
source PDFs, extracted artifacts in `LLM_OUT/`, two coding rule files, and the
two session records. `R_Rules.md`, `Mplus_Rules.md`, `SESSION_LOGS.md`, and
`DECISIONS.md` now live in `RULES_AND_LOGS/`, in the kit and in every project,
and `REFERENCES/` means source material again, which is what `AGENTS.md` always
said it meant.

The drift was partly self-inflicted. Putting the two rule files in `REFERENCES/`
this morning was the wrong call, and it was wrong at the time rather than in
hindsight, since `AGENTS.md` already defined that folder narrowly. The session
records were there by older convention and had the same problem.

`bibliography.bib` stays at the project root. It was considered for
`REFERENCES/` on the grounds that it is built from that folder's contents, which
is a real argument, but it is a project-level text file rather than a build
asset, the root convention is familiar from Quarto and RStudio projects, and
moving it into a folder that had just been narrowed would have started the drift
again.

Nine files carried the old paths. A scripted swap handled the paths themselves
and missed three categories that needed hand edits: the `mkdir` lists in
`new_project.sh` and `update-existing-projects.md`, both folder trees in
`VS-Code-workflow.md`, and prose naming the folder rather than a path.

Added `ADMIN/` to the standard project skeleton, for data use agreements, IRB
and regulatory correspondence, sponsor and collaborator email, and signed forms.

Gave it a rule in `AGENTS.md` rather than only a folder. The contract already
tells an agent that text files under `REFERENCES/` are authoritative and
quotable with an internal citation, so without an exception an agent would treat
a DUA or an email thread the same way, and quoting a confidentiality clause or a
colleague's message into a draft is a failure that looks like helpfulness while
it happens. The rule Rich chose: read a file there when pointed at it and answer
questions about it, but never search it for supporting material and never quote
or paraphrase it into a document unless asked in so many words. The exception is
stated twice, once as a project invariant and once inline in the non-PDF
resources section that would otherwise contradict it.

Audited the proposal writing instructions at Rich's prompting, and found the
skill intact but its surroundings broken.

The `grant-proposal-writing` skill itself survived untouched at 203 lines, and
all seven base part numbers it cites still resolve: Parts 1, 2.2, 2.3, 3.4, 5.6,
5.18, and 9. Adding Part 15 and collapsing Parts 11 through 17 into 11 through
14 disturbed none of them, which is the add-at-the-end rule working as intended.

The `my-writing-style` Claude skill was two revisions behind. That skill is what
the grant skill names as its base standard, and it was still the 31 July version:
0.776 similarity to the master, missing eighteen sections including all of Parts
11 through 15. I regenerated the Codex skill this morning and did not do the same
here, which is the same oversight the whole style merge existed to prevent. The
skill is now regenerated from the master, and the master's Part 10 says three
generated copies exist rather than two.

The grant adjunct had no deployment path. Deleting
`copilot-instructions-proposals.md` earlier removed the only file a grant project
could load into Copilot, and nothing regenerated it. It is now generated from the
skill into `templates/`, and `new_project.sh` copies it into every project's
`.github/`. Copilot still does not auto-load it, so the file says how to append
or invoke it, and a project that never writes a grant simply ignores it.

Both failures share a shape. The master was updated and a downstream copy was
not, in one case because I forgot and in the other because the copy had been
deleted as regenerable without anything being set up to regenerate it. The audit
step in `AgentKit_instructions.md` now names all three style copies and the grant
adjunct explicitly.

Reviewed the whole kit from four angles: a stranger cloning it, Rich running an
analysis, VS Code, and Codex and Google's tools. Built a clean clone with the
ignored files stripped, ran the scaffold under bash, renamed the analysis folder,
and rendered through pandoc.

The mechanics hold. The clone scaffolds and exits 0, renaming `R/Analysis1` to
`R/Aim1` leaves every `../../` path resolving, and pandoc renders both from the
project root and from the control file's own relative path.

One documented claim was wrong, and it was load-bearing. The kit said in three
places that Copilot loads `AGENTS.md` and `.github/copilot-instructions.md`
automatically. Only the second is true. `AGENTS.md` support in VS Code is
experimental and off by default behind `chat.useAgentsMdFile`, so without that
setting the coding contract silently does not load and a session runs on the
writing style alone. `AgentKit_overview.md` used the false version to justify
keeping the two files separate. Corrected in both places, with the setting and
the Chat Diagnostics view added to the workflow doc.

Codex works better than the kit says. `~/.codex/skills/` is the right location,
and Codex reads a repo root `AGENTS.md` natively with no setting, so a scaffolded
project plus the global writing skill already gives it the full picture.

Google's tools do not work, structurally rather than incidentally. Gemini CLI
reads `GEMINI.md` and not `AGENTS.md`, so nothing loads. Antigravity does read
`AGENTS.md`, but rules files cap at 12,000 characters and every instruction file
here exceeds it: the writing standard at 29,919, `AGENTS.md` at 12,443,
`R_Rules.md` at 13,758, `Mplus_Rules.md` at 12,636, the grant adjunct at 13,064.
Even where a file loads it truncates, and truncating this standard would drop
Part 3.5 and Part 9, which carry the positive requirements and the self-check.
Left unresolved, since fixing it means either splitting the standard, which
undoes today's merge, or declaring which tools the kit targets.

Fixed three smaller things a stranger would hit. `scrub_reference_docs.py` was
not executable. Nothing listed prerequisites, so the README now names R, Quarto,
pandoc, and `here`. And `pdf2llm` was referenced 18 times without a source; it is
at https://github.com/rnj0nes/pdf2llm, MIT, now linked from the README,
`AGENTS.md`, the project README, and the workflow doc.

Reading the pdf2llm README surfaced an interop detail. It writes to `llm_out/`
by default while the contract expects `REFERENCES/LLM_OUT/`. Those are the same
folder on a case-insensitive macOS volume and two different folders anywhere
case-sensitive. Appendix 3's single-file example already passed `-o LLM_OUT`; its
batch example did not, and now does.

Replaced the manual restructure in `update-existing-projects.md` with
`migrate_project.sh`, on Rich's design. It renames the project to
`<Project>_ORIG`, scaffolds fresh through `new_project.sh`, copies content
across, and puts the project's own reference documents back over the fresh
ones. Rebuilding beats editing in place, because the original stays whole under
another name and nothing is modified where it sits.

It moves files and edits no file contents. Rich's call, and the right one: a
wrong `sed` across a real manuscript is the failure that design avoids. The
script prints the remaining edits instead, and drops the fresh templates into the
analysis folder so the pattern to copy from sits beside the file being changed.

Testing found two bugs that reading would not have. It called `new_project.sh`
through `sh`, which lacks the constructs that script uses, so the scaffold step
failed silently. Worse, on that failure the project was already renamed and no
replacement existed, leaving the work under `_ORIG` with nothing at the expected
path. It now runs the scaffold through its own shebang and restores the original
name if the scaffold does not produce a project.

Wrote the body in the portable subset rather than zsh, because there is no zsh in
the Cowork sandbox and an untested migration script is worse than no migration
script. That decision came directly from this morning, when a zsh-only glob
guard in `new_project.sh` broke under bash.

Verified against a fake pre-restructure project of 25 files by comparing content
hashes before and after. Everything survived except the five files the current
masters deliberately replace. All three refusal paths were exercised: a missing
project, a folder without `AGENTS.md`, and a project already migrated.

The July decision against `update_project.sh` still stands and this does not
reverse it. That rejection was of continuous re-sync of masters into projects.
This runs once per project and then refuses to run again.

Swept the overview for claims the day had falsified. Four were stale: the writing
style described as seven files across three lineages, the copy count given as
two, an open item saying VS Code needs no special check for `AGENTS.md`, and a
scope line naming only `new_project.sh` among the scripts.

Prepared the kit for a public GitHub repo documenting how Rich uses AI in
research. Added `README.md` as the entry point, written around the method and
the reasoning rather than restating the contracts, and pointing at this log and
`DECISIONS.md` as the substance.

Audited for what should not be public before writing anything. `.gitignore`
excludes `REFERENCES/Jones_Writing_Samples/`, which holds six journal articles,
two pieces of unpublished grant text, and `SAGES-assets.md`, an inventory of a
live study's cohorts, ascertainment procedures, and linkage agreements. No
emails, ORCIDs, or phone numbers anywhere. The named people in the writing
standard are all published citations.

The audit found one real leak. The Stata example in section 1.3 of
`VS-Code-workflow.md` used a real in-progress analysis throughout, including an
absolute path with the username and the study folder. Genericized, and the
example project name in Appendix 2 with it.

Scrubbed and kept the `reference_*.docx` files rather than excluding them.
Inspection showed the concern was understated: each held its entire source
document, not residual fragments. 36,000 characters of the classification
manuscript, 17,000 of the BASIL II final RPPR, 9,500 of the OSCAR-S power
analysis, plus author, company, and title in the document properties.

Wrote `scrub_reference_docs.py`, which replaces run text with Lorem Ipsum and
clears properties while leaving `styles.xml`, `numbering.xml`, `settings.xml`,
and the theme byte-identical, since those are the only parts pandoc reads.
Verified by rendering the same markdown against the original and the scrubbed
copy and comparing `styles.xml` in the two outputs, which match.

Content hid in three places and each needed its own pass. Run text was the
obvious one, and a first attempt still leaked because it skipped any run
containing an XML entity, which left a whole sentence with `&gt;=30` in it.
Bookmark names and hyperlink anchors carried citation keys such as
`ref-Cohen1988`, and are attributes rather than text. `word/_rels/document.xml.rels`
held the DOI of every work each document cited. Probe-word checking found the
first two; only comparing the original's full visible vocabulary against the
scrubbed archive found the third.

Briefly excluded the reference docs before scrubbing them, which turned a
latent bug into a live one and testing caught it. With no
reference docs present, the glob in `new_project.sh` stays literal under bash,
because the `null_glob` setopt guarding it is zsh-only, so `cp` received the
pattern itself and the script exited 1. It never fired for Rich because his
shebang is zsh and his kit always had three reference docs. Anyone cloning the
repo would have hit it on their first run. Added a `[[ -e ]]` guard in the loop
and a bounds check on the array before `printf`, then verified by building a
clone with the ignored files stripped and running it under bash.

Fixing that exposed a second problem the layout sweep had missed. Section 1.3
still showed the Stata driver at the project root, because the earlier pass
updated the R example in 1.4 and not the Stata one, despite the decision that
Stata mirrors R. Rewritten for `Stata/<Analysis>/`, with the working directory
set to the project root since Stata has no `here::here()`.

Nothing in this session was verified by an actual render. There is no R and no
Quarto in the Cowork sandbox, so the drivers were confirmed as correctly copied
text, not as working code. The first real render is the test that matters, and
the likely failure points are Quarto's treatment of `output_file` when `input`
is a path, and whether the `../../` YAML paths resolve as expected from
`R/<Analysis>/`.

Cleaned up what the migration work had just created. The script had been leaving
the kit's template drivers in the analysis folder beside the user's own, which
was defended as convenient and was really just ambiguous about which driver
runs. It now keeps the two R starters, deletes the template drivers and control
files, and names the full path to the patterns in `_AgentKit/templates/`
instead.

Fixing the watermark surfaced another straggler in the same paragraph of
`VS-Code-workflow.md`, which still described the driver rendering into
`REPORTS/` and deleting a stray `REPORTS/FIGURES/` copy. That behavior went away
with `--output-dir` this afternoon. This is the sixth stale passage found by
grepping for something else.

This entry had also gone out of order. Successive additions were inserted before
its closing paragraph, leaving "Current state and next step" stranded eighty
lines from the end and describing a manual restructure that no longer exists.
Moved to the end and rewritten.

Closing two open items from 2026-07-02, without editing that entry. The
title-slide watermark is settled: the `title-slide-attributes` block is
commented out in the template, because the scaffold does not create the image
and Quarto fails rather than warns on a missing background. Uncomment it after
dropping an image at `FIGURES/watermark.png`. And the Codex copy drifting is no
longer a standing worry, since it is a generated copy with a named regeneration
step in `AgentKit_instructions.md` and an audit check beside it.

Rewrote the migration on Rich's design, because the first version renamed the
project folder and a folder shared through Dropbox loses its share the moment it
is renamed. The order is now: copy to a sibling backup, verify it, ask, empty the
folder while keeping the folder itself, build the current structure inside it,
copy content back, return anything unrecognized to its old relative path, and
name the backup `<Project>_premigration` only once all of that succeeded. Until
that final rename the backup carries an `_INCOMPLETE` suffix, so an interrupted
run cannot be mistaken for a finished one.

The verification before the erase is the load-bearing part. It compares file
count and byte total between project and backup and refuses to destroy anything
if they differ. That is what catches Dropbox online-only files, which copy as
placeholders, and where a backup of placeholders would otherwise let the script
delete the only real copy. The error names the fix: make the folder available
offline, then retry.

`new_project.sh` refuses an existing target, so the scaffold is built in a temp
folder and its contents moved into the emptied original. Left `new_project.sh`
alone rather than adding a flag to it.

Three bugs found by testing, one of them serious. The stray count reported files
nested inside copied folders, saying six where four were listed. `bibliography.bib`
and the `.rproj` fell through as unsorted instead of being placed. And the
rollback removed and recreated the project folder, which would have broken the
share, which is the single thing the whole design exists to protect. That last
one passed the first test only because the inode happened to be reused; it now
empties and refills in place. Verified by watching the inode across a successful
run and a forced failure, unchanged in both.

Confirmed lossless by content hash against a 24-file project in the old layout.
Everything reappeared except the five files the current masters replace.

Rewrote `update-existing-projects.md` around it, with the cautions collected
into a section that has to be read before running: make the folder available
offline first, run it when collaborators are not working since every file
deletes and reappears, do not delete the backup until a render succeeds, and
check for `--output-dir` first. That last one gets its own section, because
migration does not fix it. The script does not edit file contents, so an old
driver arrives with its destructive flag intact, and one run empties the dated
archive in `REPORTS/`.

Approach note, from a day with six of them. Every structural change in this
session left stale passages in files nobody expected to touch, and all six were
found by grepping the whole kit for the thing being changed rather than by
reading the files that obviously moved. Grep everything after any structural
change. Four separate defects also survived careful reading and were caught only
by execution: a scaffold copying correct names with wrong contents, a path
scheme with no root marker, a zsh-only glob guard failing under bash, and a
migration calling a script through the wrong interpreter. Run the thing.

Current state and next step. The kit is internally consistent and every claim in
it has been checked against something. On returning, the first action is a real
render: open a migrated project, run its driver, and confirm output lands in
RENDER/ and a dated copy in REPORTS/. Nothing in this session was verified that
way, because the sandbox has pandoc but no R and no Quarto, so the drivers are
correct text rather than working code. Everything else can wait.

Data handling choices: none. No study data was touched.

Open questions.
- Existing projects are on the old layout. `migrate_project.sh` rebuilds one,
  and Rich runs it per project. Any driver still passing `--output-dir` will
  empty that directory on its next run, which is the one item here that can
  destroy work rather than just leave it stale.
- The new driver pattern is unrun. No R and no Quarto in the sandbox, so the
  drivers are verified as correct text and not as working code. The likely
  failure points are Quarto's handling of `output_file` when `input` is a path,
  and whether the `../../` YAML paths resolve from `R/<Analysis>/`.
- Google's tools do not work with the kit. Gemini CLI reads `GEMINI.md` rather
  than `AGENTS.md`, and Antigravity truncates a rules file at 12,000 characters
  while every instruction file here is longer. The README says which tools are
  targeted. Fixing it would mean splitting the standard, which undoes the merge.
- `R/RDATA/` and `R/MPLUS_OUTPUT/` are flat and shared across analyses. Two
  analyses writing the same intermediate filename will overwrite each other.
  Accepted for now.
- Part 15 is untested. Whether fragments-only can carry a subtle claim is the
  part most likely to need revision after real use.
- Rich's Cowork preferences also carry writing instructions, including SEE
  paragraphs and varying sentence length. That is a separate location and no
  audit of this folder will catch it.

## 2026-08-22

Fixed a defect in `migrate_project.sh` that silently dropped R sources living in
a subfolder of `R/`. Step 6 places files with the glob `R/*.R`, which expands one
level only, so a file at `R/OldRuns/model.R` was never placed. The stray pass
should have caught it and did not, because `*` matches slashes inside a `case`
statement, so that same path matched the pattern `R/*.R` and hit `continue`.
Claimed by one pass and reported by neither, the file survived only in the
backup. The fix is one new arm, `R/*/*) ;;`, placed first so a nested path falls
through to the stray list and returns to its old relative path.

Verified by extracting the classifier and running it against eleven sample
paths, which showed the old code calling three nested files placed when nothing
had placed them. `bash -n` passes. Not verified end to end, because the session
could not run the script at all: `AGENT_KIT` is a hardcoded absolute path that
did not resolve from where the session executed, and no zsh was installed there.

Corrected `update-existing-projects.md`. It said five files are not carried back.
`is_superseded` drops seven, adding `.github/copilot-instructions-proposals.md`
and `Mplus_Rules.md`. Also added a row to the "what moves where" table stating
that anything deeper under `R/` returns to its old path and is listed.

Then a project turned up that the kit does not describe. Rich intended to migrate
`Dropbox/FH/FHP2026WG4`, and it turned out never to have been an AgentKit project
at all: no `AGENTS.md`, no control file, no driver, and a flat `R/` holding seven
`.Rmd` notebooks with their rendered companions. Migration was rejected for it.
The script would have erased and rewritten 105 MB through a shared Dropbox folder
to produce a skeleton `new_project.sh` produces without deleting anything, and
the `.Rmd` files match none of the placement globs. The project was brought onto
the layout by copying the skeleton in with no-clobber instead. What that decision
implies for the kit is below. The project's own session log has the rest.

Data handling choices: none. No study data was read or altered from here.

Open questions.

- `migrate_project.sh` may not run under its own shebang. zsh aborts on an
  unmatched glob by default, while bash leaves the pattern literal for the
  `[ -e ]` guards to catch. `new_project.sh` guards this with
  `setopt null_glob 2>/dev/null || true` and `migrate_project.sh` has no such
  line, yet line 92 globs for `*_Control.domd`, which most projects do not have.
  The 2026-08-17 entry already records a zsh-only glob guard failing under bash,
  so the shape is familiar. Unconfirmed, because no zsh was reachable from the
  session that found it. Settle this before running a migration anywhere.
- The kit has no `DATA/` convention. FHP2026WG4 keeps source data in `DATA/` at
  the project root, holding the same two datasets as `.rds`, `.dta`, and `.sav`,
  all written in one pass by one script. Mapping that onto `R/RDATA/` and
  `Stata/DTA/` would split a dataset across two trees and strand the `.sav`
  files, which have no home in the kit at all. Either the kit gains a `DATA/`
  folder, or it states where source data belongs and why.
- The kit assumes the driver and control pattern and says nothing about notebook
  projects. `migrate_project.sh` places `.R` and `.qmd` and ignores `.Rmd`
  entirely. That is defensible, since a notebook carries no driver, but nothing
  says so and the stray list is where a user first finds out.
- `new_project.sh` ends by calling `code` on the folder it creates.
  `migrate_project.sh` calls it against a hidden temporary scaffold whose
  contents are then moved out and the folder deleted, so a migration opens a VS
  Code window on a folder that disappears. Harmless, and confusing the first
  time.

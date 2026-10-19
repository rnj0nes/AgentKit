# archive_reports

`archive_reports.R` keeps this folder short. It moves the older copies of each
report into `Archive/` and leaves the newest copy of every report here. It moves
files and never deletes them.

## Running it

Run the script with `Rscript`, which comes with every R installation. The
command is the same on macOS, Windows, and Ubuntu. Open a terminal (Terminal on
macOS, PowerShell or Command Prompt on Windows), move into this folder, and
type:

```
Rscript archive_reports.R
```

You can also run it from the project root with `Rscript REPORTS/archive_reports.R`.
The script works on the folder it sits in, not the folder your terminal is in,
so both commands do the same thing. To tidy some other folder, name it as an
argument: `Rscript archive_reports.R path/to/folder`.

On Windows, if the terminal reports that `Rscript` is not recognized, R is
installed but not on the PATH. Use the full path instead, for example
`"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" archive_reports.R`, with your own
R version number. The script uses base R only, so it needs no packages.

## How it decides what is old

The script finds each report from its file name, so it needs no list of report
names. It reads every name as a stub, a date, an optional time, an optional
tag, and an extension. For example, `MS_Appendix_1_2026-10-17_0851_edited.docx`
has stub `MS_Appendix_1`, date 2026-10-17, time 08:51, tag `edited`, and
extension `.docx`. Files that share a stub, tag, and extension are copies of
one report.

A plain render and an edited copy count as two different reports. The script
cannot tell from a plain render's name whether it came before or after a
same-day edit, so it keeps the newest of each. For example, if this folder
holds `MS_Appendix_1_2026-10-18.docx` and `MS_Appendix_1_2026-10-18_1532_edited.docx`,
both stay here and every older copy of either goes to `Archive/`. The same stub
with a different extension is also a different report, so
`MS_Appendix_1.html` and `MS_Appendix_1.docx` each keep their own newest copy.

Newest means the latest date in the file name, then the latest time. The
script ignores the date your computer shows for when a file was last changed,
because Dropbox and other sync tools rewrite it.

The script handles `.docx`, `.html`, `.pdf`, and `.pptx` files. It leaves
everything else where it is: files without a date in the name, other file
types, the `Archive/` folder itself, and the temporary `~$` files Word creates
while a document is open.

## HTML reports with a _files folder

An HTML report that is not self-contained keeps its images and scripts in a
folder named after it, such as `Proj_slides_2026-10-10_files/`. That folder
moves to `Archive/` together with its HTML file.

## Name clashes

If `Archive/` already holds a file with the same name, the moved copy gets `_1`
before the extension, then `_2`, and so on. For example, a second
`MS_Appendix_1_2026-09-22.docx` arrives as `MS_Appendix_1_2026-09-22_1.docx`.
An HTML file's `_files` folder takes the same number, and the script rewrites
the links inside the moved HTML file so it still finds its images.

## When a move fails

A file that another program has open, which is common on Windows, cannot be
moved. The script reports it as FAILED, moves everything else, and ends with a
non-zero exit status. Close the file and run the script again. Running it twice
is safe, because the second run finds nothing old left to move.

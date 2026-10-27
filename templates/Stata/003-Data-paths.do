* =============================================================================
* Stata/<Analysis>/003-Data-paths.do
* Reads this project's data locations from a paths file kept outside the
* project, and sets the globals $SOURCE, $DERIVED, $WORK, $SHARE_DATA, and
* $MPLUS.
*
* The paths file is ~/.agentkit/data_paths/<Project>.txt, where <Project> is
* the name of the project root folder. Set the environment variable
* AGENTKIT_DATA_PATHS to use a different folder. The file holds one KEY=path
* line per location, the same file the R helper reads. SHARE_DATA may be
* left empty.
*
* Run this from the project root, after the driver sets the working
* directory there. Messages name the key that failed, never the location.
*
* Use: use "$SOURCE/hcap.dta", clear
* =============================================================================

version 16

local pwd = subinstr("`c(pwd)'", char(92), "/", .)
local proj = substr("`pwd'", strrpos("`pwd'", "/") + 1, .)

local home : env HOME
local dir : env AGENTKIT_DATA_PATHS
if "`dir'" == "" local dir "`home'/.agentkit/data_paths"
local pf "`dir'/`proj'.txt"

capture confirm file "`pf'"
if _rc {
    display as error "Data paths file not found: `pf'"
    display as error "Create it with one KEY=path line each for SOURCE, DERIVED, WORK, SHARE_DATA, and MPLUS."
    exit 601
}

foreach k in SOURCE DERIVED WORK SHARE_DATA MPLUS {
    global `k' ""
    local seen_`k' 0
}

tempname fh
file open `fh' using "`pf'", read text
file read `fh' line
while r(eof) == 0 {
    local line = strtrim(`"`line'"')
    local eq = strpos(`"`line'"', "=")
    if `"`line'"' != "" & substr(`"`line'"', 1, 1) != "#" & `eq' > 1 {
        local key = strtrim(substr(`"`line'"', 1, `eq' - 1))
        local val = strtrim(substr(`"`line'"', `eq' + 1, .))
        if substr(`"`val'"', 1, 1) == "~" local val = "`home'" + substr(`"`val'"', 2, .)
        if inlist("`key'", "SOURCE", "DERIVED", "WORK", "SHARE_DATA", "MPLUS") {
            global `key' `"`val'"'
            local seen_`key' 1
        }
    }
    file read `fh' line
}
file close `fh'

foreach k in SOURCE DERIVED WORK SHARE_DATA MPLUS {
    if !`seen_`k'' {
        display as error "Data paths file lacks a `k'= line: `pf'"
        exit 198
    }
}

foreach k in SOURCE DERIVED WORK MPLUS {
    if `"${`k'}"' == "" {
        display as error "Data paths file leaves `k' empty."
        exit 198
    }
    mata: st_local("ok", strofreal(direxists(st_global("`k'"))))
    if !`ok' {
        display as error "The `k' location in `proj'.txt does not exist on this machine."
        display as error "Create it, or check that the drive holding the data is mounted."
        exit 601
    }
}

if `"$SHARE_DATA"' != "" {
    mata: st_local("ok", strofreal(direxists(st_global("SHARE_DATA"))))
    if !`ok' {
        display as error "The SHARE_DATA location in `proj'.txt does not exist."
        exit 601
    }
}

display as text "Data locations loaded for project `proj'"

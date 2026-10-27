# =============================================================================
# R/<Analysis>/005-Data-dictionary.R
# Builds DATA_DICTIONARY/, which describes the data in SOURCE and DERIVED so
# agents can write code against real file names, variable names, labels, and
# distributions without ever reading the data.
#
# update_data_dictionary() runs at the top of each driver. It is cheap when
# nothing has changed: it compares each data file's size and modification
# time with what its entry recorded, and reads a data file only when its entry
# is missing or out of date.
#
# One entry per stub. A stub is a file's path inside its location without the
# extension, so SOURCE/wave2/baseline.dta and SOURCE/wave2/baseline.sav share
# the stub wave2/baseline and the entry SOURCE__wave2__baseline.md. The entry
# is built from the first format present in this order: dta, sav, por,
# sas7bdat, xpt, rds, rdata, rda, csv, tsv, xlsx, xls. It lists every format
# present.
#
# Each entry holds structure and distributions, never values from a record:
#   - categorical variables: a count per value, with value labels
#   - numeric variables: n, mean, SD, and the 25th, 50th, and 75th
#     percentiles, plus the 5th and 95th from 100 values up; never the
#     minimum or maximum
#   - missing codes: a count per code
#   - dates: earliest and latest year only
#   - text variables: number of distinct values and number missing only
# Counts from 1 to 10 show as "<11". When only one count in a variable is
# suppressed, the next smallest is suppressed too, so the hidden count cannot
# be worked out from the total. Numeric summaries are suppressed when fewer
# than 11 values are present.
#
# Entries whose data file has gone are reported and left in place.
# STUDY_NOTES.md and ID_VARIABLES.txt are written by hand and never touched.
#
# Prereq: source 000-Libraries.R and 003-Data-paths.R first. Reading .dta,
# .sav, .por, .sas7bdat, and .xpt files needs haven; .xlsx and .xls need
# readxl.
# =============================================================================

.dd_formats <- c("dta", "sav", "por", "sas7bdat", "xpt", "rds", "rdata", "rda",
                 "csv", "tsv", "xlsx", "xls")
.dd_min_cell <- 11

.dd_read <- function(path, ext) {
  need <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("package ", pkg, " is needed to read .", ext, " files", call. = FALSE)
    }
  }
  switch(ext,
    dta      = { need("haven"); list(data = haven::read_dta(path)) },
    sav      = { need("haven"); list(data = haven::read_sav(path, user_na = TRUE)) },
    por      = { need("haven"); list(data = haven::read_por(path, user_na = TRUE)) },
    sas7bdat = { need("haven"); list(data = haven::read_sas(path)) },
    xpt      = { need("haven"); list(data = haven::read_xpt(path)) },
    rds      = list(data = readRDS(path)),
    rdata    = , rda = {
      e <- new.env()
      nm <- load(path, envir = e)
      mget(nm, envir = e)
    },
    csv      = list(data = utils::read.csv(path, stringsAsFactors = FALSE)),
    tsv      = list(data = utils::read.delim(path, stringsAsFactors = FALSE)),
    xlsx     = , xls = {
      need("readxl")
      sh <- readxl::excel_sheets(path)
      setNames(lapply(sh, function(s) as.data.frame(readxl::read_excel(path, sheet = s))), sh)
    }
  )
}

# ---- counts with small-cell suppression --------------------------------------
.dd_suppress <- function(n) {
  out <- as.character(n)
  small <- n > 0 & n < .dd_min_cell
  if (sum(small) == 1) {
    rest <- which(!small & n > 0)
    if (length(rest)) small[rest[which.min(n[rest])]] <- TRUE
  }
  out[small & n < .dd_min_cell] <- "<11"
  out[small & n >= .dd_min_cell] <- "suppressed"
  out
}

.dd_fmt <- function(x) trimws(formatC(x, digits = 4, format = "g"))

.dd_type <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return("date")
  if (is.factor(x) || is.logical(x)) return("categorical")
  if (inherits(x, "haven_labelled")) {
    labs <- attr(x, "labels")
    v <- unclass(x)
    if (is.character(v)) return("categorical")
    present <- unique(v[!is.na(v)])
    if (length(present) && all(present %in% labs)) return("categorical")
    return("numeric (labelled codes)")
  }
  if (is.character(x)) return("text")
  if (is.numeric(x)) return("numeric")
  paste(class(x), collapse = "/")
}

.dd_label <- function(x) {
  l <- attr(x, "label", exact = TRUE)
  if (is.null(l)) "" else gsub("[\r\n|]", " ", as.character(l))
}

.dd_format <- function(x) {
  for (a in c("format.stata", "format.spss", "format.sas")) {
    f <- attr(x, a, exact = TRUE)
    if (!is.null(f)) return(f)
  }
  ""
}

# Missing values: R NA, haven tagged NA (Stata .a to .z), SPSS user missing.
.dd_missing <- function(x) {
  res <- list()
  v <- x
  if (inherits(x, "haven_labelled_spss")) {
    nav <- attr(x, "na_values"); nar <- attr(x, "na_range")
    um <- rep(FALSE, length(x))
    if (!is.null(nav)) um <- um | unclass(x) %in% nav
    if (!is.null(nar)) um <- um | (unclass(x) >= nar[1] & unclass(x) <= nar[2])
    um[is.na(um)] <- FALSE
    if (any(um)) {
      tab <- table(unclass(x)[um])
      for (k in names(tab)) res[[paste0("user missing ", k)]] <- as.integer(tab[[k]])
    }
    v <- unclass(x); v[um] <- NA
  }
  if (is.double(unclass(x)) && requireNamespace("haven", quietly = TRUE)) {
    tags <- haven::na_tag(unclass(x))
    if (any(!is.na(tags))) {
      tab <- table(tags[!is.na(tags)])
      for (k in names(tab)) res[[paste0(".", k)]] <- as.integer(tab[[k]])
    }
    plain <- is.na(unclass(x)) & is.na(tags)
    if (any(plain)) res[["NA"]] <- sum(plain)
  } else if (any(is.na(unclass(x)))) {
    res[["NA"]] <- sum(is.na(unclass(x)))
  }
  list(counts = unlist(res), values = v)
}

.dd_describe_var <- function(x) {
  type <- .dd_type(x)
  miss <- .dd_missing(x)
  v    <- miss$values
  labs <- attr(x, "labels", exact = TRUE)
  lines <- character(0)

  label_of <- function(code) {
    if (is.null(labs)) return("")
    hit <- names(labs)[match(code, unclass(labs))]
    ifelse(is.na(hit), "", paste0(" \"", hit, "\""))
  }

  if (type == "categorical") {
    vv <- if (is.factor(v)) as.character(v) else unclass(v)
    tab <- table(vv, useNA = "no")
    keys <- names(tab); n <- as.integer(tab)
    if (!is.null(labs) && !is.factor(v)) {
      # include labelled codes with zero count, so the agent sees every code
      extra <- setdiff(as.character(unclass(labs)), keys)
      keys <- c(keys, extra); n <- c(n, rep(0L, length(extra)))
    }
    allc <- c(n, miss$counts)
    sup  <- .dd_suppress(allc)
    for (i in seq_along(keys)) {
      lab <- if (is.factor(v) || is.logical(v)) "" else label_of(type.convert(keys[i], as.is = TRUE))
      lines <- c(lines, sprintf("    %s%s: %s", keys[i], lab, sup[i]))
    }
    if (length(miss$counts)) {
      ms <- sup[-seq_along(keys)]
      for (i in seq_along(miss$counts)) {
        lines <- c(lines, sprintf("    missing %s: %s", names(miss$counts)[i], ms[i]))
      }
    }
  } else if (startsWith(type, "numeric")) {
    vv <- as.numeric(unclass(v))
    coded <- character(0)
    if (type == "numeric (labelled codes)") {
      is_code <- vv %in% unclass(labs)
      ct <- table(vv[is_code])
      coded <- names(ct)
      code_n <- as.integer(ct)
      vv[is_code] <- NA
    } else code_n <- integer(0)
    ok <- vv[!is.na(vv)]
    if (length(ok) >= .dd_min_cell) {
      q <- stats::quantile(ok, c(.05, .25, .5, .75, .95), names = FALSE, type = 7)
      lines <- c(lines, sprintf("    n %d, mean %s, SD %s", length(ok), .dd_fmt(mean(ok)),
                                .dd_fmt(stats::sd(ok))))
      # With fewer than 100 values the 5th and 95th percentiles sit close to
      # single records, so they are shown only from 100 values up.
      lines <- c(lines, if (length(ok) >= 100) {
        sprintf("    p5 %s, p25 %s, p50 %s, p75 %s, p95 %s",
                .dd_fmt(q[1]), .dd_fmt(q[2]), .dd_fmt(q[3]), .dd_fmt(q[4]), .dd_fmt(q[5]))
      } else {
        sprintf("    p25 %s, p50 %s, p75 %s", .dd_fmt(q[2]), .dd_fmt(q[3]), .dd_fmt(q[4]))
      })
    } else {
      lines <- c(lines, sprintf("    n %s; summaries suppressed", .dd_suppress(length(ok))))
    }
    allc <- c(code_n, miss$counts)
    if (length(allc)) {
      sup <- .dd_suppress(allc)
      for (i in seq_along(coded)) {
        lines <- c(lines, sprintf("    code %s%s: %s", coded[i],
                                  label_of(as.numeric(coded[i])), sup[i]))
      }
      ms <- sup[-seq_along(coded)]
      if (!length(coded)) ms <- sup
      for (i in seq_along(miss$counts)) {
        lines <- c(lines, sprintf("    missing %s: %s", names(miss$counts)[i], ms[i]))
      }
    }
  } else if (type == "date") {
    ok <- v[!is.na(v)]
    if (length(ok) >= .dd_min_cell) {
      yrs <- as.integer(format(range(ok), "%Y"))
      lines <- c(lines, sprintf("    years %d to %d", yrs[1], yrs[2]))
    } else lines <- c(lines, "    fewer than 11 dates; range suppressed")
    if (length(miss$counts)) lines <- c(lines, sprintf("    missing: %s", .dd_suppress(sum(miss$counts))))
  } else if (type == "text") {
    vv <- unclass(v)
    blank <- is.na(vv) | !nzchar(trimws(vv))
    lines <- c(lines, sprintf("    distinct values %d, missing or blank %s",
                              length(unique(vv[!blank])), .dd_suppress(sum(blank))))
  } else {
    lines <- c(lines, "    not summarized")
  }
  list(type = type, lines = lines)
}

.dd_describe_df <- function(df, id_vars) {
  out <- character(0)
  vars <- names(df)
  out <- c(out, sprintf("Rows: %d. Columns: %d.", nrow(df), ncol(df)), "")

  idp <- vars[tolower(vars) %in% tolower(id_vars)]
  if (length(idp)) {
    for (id in idp) {
      nd <- length(unique(df[[id]][!is.na(df[[id]])]))
      out <- c(out, sprintf("ID variable `%s`: %d distinct values, %s.", id, nd,
                            if (nd == nrow(df)) "one row per value (wide layout)"
                            else "repeated across rows (long layout)"))
    }
    if (length(idp) > 1) {
      u <- !anyDuplicated(df[idp])
      out <- c(out, sprintf("Together, %s %s identify a row.",
                            paste0("`", idp, "`", collapse = " and "),
                            if (u) "uniquely" else "do not uniquely"))
    }
  } else {
    out <- c(out, "No variable listed in ID_VARIABLES.txt is present.")
  }
  out <- c(out, "", "## Variables", "",
           "| Variable | Type | Label | Format |", "|---|---|---|---|")
  descs <- lapply(vars, function(v) {
    if (v %in% idp) list(type = .dd_type(df[[v]]), lines = character(0)) else .dd_describe_var(df[[v]])
  })
  rows  <- data.frame(variable = vars,
                      type   = vapply(descs, `[[`, "", "type"),
                      label  = vapply(df, .dd_label, ""),
                      format = vapply(df, .dd_format, ""),
                      stringsAsFactors = FALSE)
  out <- c(out, sprintf("| `%s` | %s | %s | %s |", rows$variable, rows$type, rows$label, rows$format))
  out <- c(out, "", "## Distributions", "")
  for (i in seq_along(vars)) {
    body <- if (vars[i] %in% idp) "    ID variable; not summarized" else descs[[i]]$lines
    out <- c(out, sprintf("- `%s` (%s)", vars[i], rows$type[i]), body)
  }
  list(md = out, vars = rows)
}

.dd_stamp <- function(info) {
  sprintf("<!-- agentkit-dict file=%s size=%.0f mtime=%s formats=%s -->",
          basename(info$path), info$size, format(info$mtime, "%Y-%m-%dT%H:%M:%S"),
          paste(info$formats, collapse = ","))
}

update_data_dictionary <- function(keys = c("SOURCE", "DERIVED")) {
  if (is.null(.agentkit_paths)) {
    cat("Data dictionary: no data locations set yet; skipped\n")
    return(invisible(character(0)))
  }
  dict_dir <- here::here("DATA_DICTIONARY")
  dir.create(dict_dir, showWarnings = FALSE)
  id_vars <- if (exists(".agentkit_id_vars")) .agentkit_id_vars() else {
    f <- file.path(dict_dir, "ID_VARIABLES.txt")
    if (file.exists(f)) { z <- trimws(readLines(f, warn = FALSE)); z[nzchar(z) & !startsWith(z, "#")] } else character(0)
  }

  wanted <- character(0)
  built <- 0L
  for (key in keys) {
    root <- data_path(key)
    files <- list.files(root, recursive = TRUE, all.files = FALSE)
    ext   <- tolower(tools::file_ext(files))
    keep  <- ext %in% .dd_formats
    files <- files[keep]; ext <- ext[keep]
    if (!length(files)) next
    stub  <- sub("\\.[^.]+$", "", files)
    for (s in unique(stub)) {
      i  <- which(stub == s)
      fm <- ext[i][order(match(ext[i], .dd_formats))]
      primary <- files[i][order(match(ext[i], .dd_formats))][1]
      path <- file.path(root, primary)
      fi <- file.info(path)
      info <- list(path = path, size = fi$size, mtime = fi$mtime, formats = fm)
      entry <- paste0(key, "__", gsub("/", "__", s))
      wanted <- c(wanted, entry)
      md_file <- file.path(dict_dir, paste0(entry, ".md"))
      stamp <- .dd_stamp(info)
      if (file.exists(md_file) && identical(readLines(md_file, n = 1, warn = FALSE), stamp)) next

      objs <- tryCatch(.dd_read(path, fm[1]), error = function(e) e)
      md <- c(stamp, sprintf("# %s: %s", key, s), "",
              "Generated by 005-Data-dictionary.R. Do not edit; this file is rebuilt when its data file changes.", "",
              sprintf("Location: `%s`. Formats present: %s. Described from: `%s`. Modified: %s.",
                      key, paste0(".", fm, collapse = ", "), basename(primary),
                      format(fi$mtime, "%Y-%m-%d")), "")
      vars_all <- NULL
      if (inherits(objs, "error")) {
        md <- c(md, sprintf("Not described: %s.", conditionMessage(objs)))
      } else {
        for (nm in names(objs)) {
          o <- objs[[nm]]
          if (length(objs) > 1) md <- c(md, sprintf("# Object or sheet: %s", nm), "")
          if (is.data.frame(o)) {
            d <- .dd_describe_df(as.data.frame(o), id_vars)
            md <- c(md, d$md, "")
            d$vars$entry <- entry; d$vars$object <- nm
            vars_all <- rbind(vars_all, d$vars)
          } else {
            md <- c(md, sprintf("Object of class %s; not a data frame, not described.",
                                paste(class(o), collapse = "/")), "")
          }
        }
      }
      writeLines(md, md_file)
      if (!is.null(vars_all)) {
        utils::write.csv(vars_all, file.path(dict_dir, paste0(entry, ".vars.csv")), row.names = FALSE)
      }
      built <- built + 1L
      cat("Data dictionary: wrote", basename(md_file), "\n")
    }
  }

  # Combined variable list, rebuilt from the per-entry tables each run.
  vf <- list.files(dict_dir, pattern = "\\.vars\\.csv$", full.names = TRUE)
  vf <- vf[sub("\\.vars\\.csv$", "", basename(vf)) %in% wanted]
  if (length(vf)) {
    all <- do.call(rbind, lapply(vf, utils::read.csv, stringsAsFactors = FALSE))
    utils::write.csv(all, file.path(dict_dir, "_ALL_VARIABLES.csv"), row.names = FALSE)
  }

  # Entries whose data file has gone: report, never delete.
  have <- sub("\\.md$", "", list.files(dict_dir, pattern = "\\.md$"))
  gen  <- have[vapply(have, function(h) {
    isTRUE(startsWith(readLines(file.path(dict_dir, paste0(h, ".md")), n = 1, warn = FALSE), "<!-- agentkit-dict"))
  }, logical(1))]
  orphans <- setdiff(gen, wanted)
  if (length(orphans)) {
    cat("Data dictionary: no data file found for", paste0(orphans, ".md", collapse = ", "),
        "(left in place)\n")
  }
  if (built == 0L) cat("Data dictionary: up to date\n")
  invisible(wanted)
}

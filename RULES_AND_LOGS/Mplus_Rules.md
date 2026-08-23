# Mplus Rules and Gotchas

Practical conventions for running Mplus from R with MplusAutomation.
Audience: LLM coding agents and future maintainers.

## 1. Canonical run structure (R -> Mplus -> H5 -> outputs)

Use this sequence for every model script:

1. Define `mplus_outdir` as `here::here("R", "MPLUS_OUTPUT", "<analysis-id>")`.
2. Build an `MplusAutomation::mplusObject(...)`.
3. Write `.inp` and `.dat` with `mplusModeler(..., run = FALSE)` on every run.
4. Execute with `MplusAutomation::runModels(target = inp_file)`.
5. Read model results from `H5RESULTS` via `mplush5`.
6. Save extracted tables back to `R/MPLUS_OUTPUT/<analysis-id>/`.

Minimal pattern:

```r
mplus_outdir <- here::here("R", "MPLUS_OUTPUT", "021-IRT-01")
dir.create(mplus_outdir, showWarnings = FALSE, recursive = TRUE)

inp_file <- file.path(mplus_outdir, "spelling_irt.inp")
dat_file <- file.path(mplus_outdir, "spelling_irt.dat")

MplusAutomation::mplusModeler(
  object = mplus_model,
  dataout = dat_file,
  modelout = inp_file,
  run = FALSE
)

MplusAutomation::runModels(target = inp_file)
```

## 2. Variable naming and mapping

Mplus truncates variable names to 8 characters in output tables.
Always rename modeled items to `u1`, `u2`, ... before passing to Mplus.

```r
mplus_vars <- paste0("u", seq_along(item_vars))
var_map <- setNames(item_vars, mplus_vars)
title_vars <- paste(paste0(mplus_vars, "=", item_vars), collapse = "; ")
```

Encode the mapping in `TITLE` so the `.inp` remains self-documenting.
After extraction, map back using `var_map[mplus_var]`.

## 3. Identification rule for single-factor models

If identifying with `f@1` (factor variance fixed), free all loadings.
Because Mplus defaults to fixing the first loading to 1, explicitly place `*`
after the first indicator.

```r
MODEL = paste0(
  "f BY ", mplus_vars[1], "* ", paste(mplus_vars[-1], collapse = " "), " ;\n",
  "f@1;"
)
```

Do not use `f BY u1 u2 u3 u4 * ;` because this only frees the last loading.

## 4. H5 output conventions

Use `SAVEDATA: H5RESULTS = ...;` for model results.
Do not use `RESULTS = ...;` when you need HDF5 model tables.

```r
SAVEDATA = "H5RESULTS = spelling_irt_h5results.h5;"
```

Important:
- Keep the `SAVEDATA` filename short and path-free (Mplus has a 90-character line limit).
- Use filename only, not absolute/relative path, inside `SAVEDATA`.
- Resolve full path from `mplus_outdir` in R after the run.

## 5. **CRITICAL: Always use IDVARIABLE with SAVEDATA**

**Mplus sorts FSCORES and other saved data by grouping variables, NOT by input row order.**

When using `SAVEDATA: SAVE = FSCORES;` (or other save options), you **must** include an `IDVARIABLE` in the VARIABLE section to preserve row alignment with your input data.

```r
VARIABLE = paste0(
  "USEVARIABLES = ", paste(mplus_vars, collapse = " "), " ;\n",
  "CATEGORICAL  = ", paste(mplus_vars, collapse = " "), " ;\n",
  "GROUPING = women(1=women 0=men) ;\n",
  "IDVARIABLE = rownum ;"  # <-- REQUIRED with SAVEDATA
)
```

**Why this matters:**
- Mplus automatically sorts output files by group (e.g., men=0 first, then women=1)
- Your input data maintains its original row order
- Without IDVARIABLE, row 1 in the .dat file does NOT match row 1 in the output .dat file
- This causes catastrophic misalignment when merging back to R (e.g., 586/659 rows misaligned)

**Implementation pattern:**

```r
# In data preparation (before passing to Mplus)
spelling_df$rownum <- seq_len(nrow(spelling_df))

# In Mplus VARIABLE section
IDVARIABLE = rownum ;

# When reading Mplus output
fscores <- read.table(fscores_path, header = FALSE)
# IDVARIABLE appears second-to-last in output, before grouping variable
names(fscores) <- c(mplus_vars, "F", "F_SE", "rownum", "women")

# Merge back to R data by rownum
spelling_df <- merge(spelling_df, fscores[, c("rownum", "F")], 
                     by = "rownum", all.x = TRUE, sort = FALSE)
```

**IDVARIABLE column position in output:**
- MLR FSCORES: `U1 U2 U3 U4 F F_SE ROWNUM` (no grouping) or `... ROWNUM WOMEN` (with grouping, ROWNUM second-to-last)
- WLSMV FSCORES: same pattern as MLR
- BAYES FSCORES (`SAVE = FSCORES(m)`): `U1 U2 U3 U4 +F F_mean F_median F_standard_deviation F_25_value F_975_value ROWNUM`
  - The `+F` column is repeated `m` times (one plausible value draw per imputation)
  - `runmplus_load_savedata` requires `m` argument: `RNJmisc:::runmplus_load_savedata(out_path, m = 1)`
  - After reading with `m=1`, the draw column is named `fm1`; summary columns are `f_mean`, `f_standard_deviation`, etc.
  - Use `fm1` directly as the plausible value — do NOT re-simulate with `rnorm()`

**Bayes FSCORES correct ANALYSIS + SAVEDATA syntax:**
```
ANALYSIS:
  ESTIMATOR = BAYES;
  BSEED = 3481;        ! seed for the posterior sampler — ensures the same draw
                       ! per record given the same data and model (reproducibility)
  CHAINS = 2;
  BITERATIONS = 5000;

SAVEDATA:
  SAVE = FSCORES(1);   ! number of draws in parentheses — NOT NIMPUTATIONS
  FACTORS = f;         ! name the factor(s) to save scores for
  FILE = outfile.dat;
```
`NIMPUTATIONS` is **not** a valid Mplus keyword — it will cause "Unknown option" error.
Always set `BSEED` so the plausible value draw is reproducible.

**Reading Bayes FSCORES in R:**
```r
bayes_savedata <- RNJmisc:::runmplus_load_savedata(bayes_out, m = 1)$data |>
  tibble::as_tibble() |>
  dplyr::rename_with(tolower)
# fm1 = one plausible value draw; f_mean = posterior mean; f_standard_deviation = posterior SD
bayes_scores <- spelling_df |>
  dplyr::left_join(dplyr::select(bayes_savedata, rownum, fs_draw = fm1), by = "rownum")
```

Never assume input row order matches output row order. Always use IDVARIABLE and merge by ID.

## 6. `H5RESULTS` versus `.gh5`

`PLOT: TYPE = PLOT3` writes a `.gh5` graphics file.
`SAVEDATA: H5RESULTS = ...;` writes model results HDF5.

Use them for different tasks:
- `H5RESULTS` + `mplush5::mplus.print.model.results()` for parameter/result tables.
- `.gh5` + `rhdf5` for low-level graphics arrays (`irt_data`, `individual_data`).

Do not assume `.gh5` can replace `H5RESULTS` for all parameter extraction.

## 7. Reading H5 results with `mplush5`

Canonical extraction:

```r
E <- mplush5::mplus.print.model.results(h5results_path)
```

Expected columns include:
- `Section`
- `Statement`
- `Estimate`
- `S.E.`
- `Estimate/S.E.`
- `Two-Tailed P-Value`
- `Group` (multi-group models)

For categorical outcomes, thresholds are in `Section == "Thresholds"`.
Do not assume an `Intercepts` section exists.

## 8. Multi-group extraction safeguards

When filtering by group, avoid substring matching (for example, `MEN` matches `WOMEN`).
Use exact normalized labels:

```r
grp_match <- function(E, group_label) {
  toupper(trimws(E$Group)) == paste("GROUP", toupper(group_label))
}
```

For group-specific parameters, use strict checks and fail fast if no row matches.

## 9. Save sidecar outputs for reproducibility

After model runs, save any derived tables (for example item parameters, DIF area summaries)
next to the model artifacts under the same `R/MPLUS_OUTPUT/<analysis-id>/` folder.

Examples:
- `spelling_irt_params.csv`
- `girder_area_stats.csv`

This keeps downstream QMD slides and diagnostics stable.

## 10. Download-slide compatibility for `.inp` files

If embedding `.inp` content in HTML downloads, sanitize `FILE = "...dat";`
lines to keep only the data filename basename.
This prevents exposing machine-specific paths in rendered slides.

## 11. Factor score determinacy with categorical variables

**Factor score determinacy is not available when there is at least one categorical dependent variable.**

Mplus does not report R-SQUARE for the latent factor when using categorical indicators with WLSMV estimation. The R-SQUARE section in the output only shows reliability estimates for the observed categorical indicators (proportion of variance explained), not for the latent factor itself.

To compute determinacy for IRT models with categorical items:
1. Extract standardized factor loadings from the STDYX section
2. Manually compute: ρ = √(Σλ²/(Σλ² + Σ(1-λ²)))
3. Square the result (ρ²) to put it on the same scale as coefficient alpha

This computation assumes the factor variance is scaled to 1.

## 12. Package reference

Running Mplus from R:
- `MplusAutomation` from CRAN.

Reading HDF5 output:
- `mplush5` from GitHub (`dougtommet/mplush5`).
- `rhdf5` from Bioconductor for low-level HDF5 access.

DIF-specific post-processing used in this project:
- `DIFMagnitude` from GitHub (`rnj0nes/DIFMagnitude`).

## 13. Modification indices output convention

When requesting modification indices for reporting or triage slides, prefer
`MODINDICES(-0)` over `MODINDICES(ALL)` in the Mplus `OUTPUT` statement.

Example:

```r
OUTPUT = "STDYX MODINDICES(-0);"
```

Rationale:
- Keeps the syntax explicit for MI extraction workflows in this project.
- Aligns scalar/partial-scalar diagnostics with the current Etude 06 pipeline.

## 14. The "DIFFTEST Shuffle" (item-level invariance release)

Project standard for releasing measurement constraints in WLSMV multiple-group
CFA when modification indices flag an item as non-invariant. Implemented in
Etude `20260513_08` and recommended for any subsequent invariance follow-up.

**Premise.** If *any* measurement parameter for an item (loading, intercept or
threshold, residual variance) shows evidence of DIF, treat the **whole item** as
non-invariant. That is, release all of that item's measurement parameters
across groups simultaneously, rather than one at a time.

**Procedure.** Let `M_c` be the current (more-restrictive) baseline model.
To test releasing item `k`:

1. Build derivative model `M_d` that frees, across groups, every measurement
   parameter tied to item `k`:
   - continuous indicator: loading + intercept + residual variance
   - categorical indicator: loading + thresholds + scale factor (where applicable)
   All other parameters retain their `M_c` constraints. Save with
   ```
   SAVEDATA: DIFFTEST = <item>_deriv.dat ;
              H5RESULTS = <model>_deriv.h5 ;
   ```
2. Re-fit `M_c` (same constraints, same MODEL block) but add
   ```
   ANALYSIS: DIFFTEST = <item>_deriv.dat ;
   ```
   The output of this re-fit reports the WLSMV χ²-difference test of `M_c`
   nested in `M_d`.

3. Decision rule. Accept the release iff **both**:
   - DIFFTEST p-value < .05, and
   - ΔCFI = CFI(`M_d`) − CFI(`M_c`) ≥ 0.010.

   Otherwise reject; `M_c` remains baseline and try the next candidate item.

4. If accepted, `M_d` becomes the new baseline. Extract its top modification
   indices from H5 (`Model Modification Indices/Results` + `Statements`), apply
   the same filter (e.g. `MEM BY <item>` loadings + `Means/Intercepts/Thresholds`
   for that group), pick the new top item, and repeat from step 1.

**Notes.**
- The DIFFTEST file is **saved by the less-restrictive parent** (`M_d`) and
  **read by the more-restrictive child** (`M_c`). The χ²-difference statistic
  appears in `M_c`'s `.out` under "Chi-Square Test for Difference Testing".
- Reuse the same Mplus `.dat` file across both runs to avoid spurious data
  differences.
- Both DIFFTEST significance and ΔCFI thresholds must clear; significance
  alone in large samples will flag tiny, substantively trivial differences.
- This is more conservative than per-parameter MI releases but easier to
  defend substantively and matches how cognitive measures are interpreted at
  the item level rather than the per-parameter level.

**Results-slide display conventions (mandatory).**

When presenting the DIFFTEST Shuffle comparison table, columns MUST appear
in this exact order:

1. `Comparison` — text label (e.g., "Constrained vs Derivative (y2 free)")
2. **Δχ²** — chi-square difference statistic
3. **Δdf** — degrees-of-freedom difference
4. **p** — DIFFTEST p-value
5. **ΔCFI** — placed LAST

Rationale: Δχ², Δdf, and p are the three components of a single
inferential statement and must be read together as a unit. ΔCFI is a
separate practical-significance criterion and goes at the end so the
reader's eye sweeps "test → effect-size" left-to-right. Do **not** insert
ΔCFI between Δdf and p.

In addition, every DIFFTEST Shuffle results slide must include a small
side-by-side table of the **focal-group factor mean (and variance) under
`M_c` vs `M_d`**, with "Estimate (SE)" formatting and a `Change` column
showing the shift in the focal-group factor mean attributable to the
release. This makes visible whether releasing the candidate item moved
the substantive group comparison, not just the fit indices.


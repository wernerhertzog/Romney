## Test environments

- Local macOS check: macOS Tahoe 26.4.1, R 4.5.2
- `R CMD check --as-cran` on `Romney_0.1.0.tar.gz`
- win-builder `R-devel`: Windows Server 2022 x64, R Under development (2026-05-10 r90034 ucrt)

## R CMD check results

0 errors | 0 warnings | 3 notes locally; 1 note on win-builder

Notes:

- `New submission`
- `README.md`/`NEWS.md` cannot be checked without `pandoc` installed on the local machine
- HTML validation note due to local `tidy` version not being recent enough on the local machine

These notes are unrelated to package functionality.

## Resubmission

This is a resubmission. In response to CRAN feedback, the package title and
description were revised to:

- remove the redundant phrase `in R` from the title
- remove the opening phrase `Tools for` from the description
- format the software name `'UCINET'` in single quotes

## Comments

`Romney` provides classical cultural consensus analysis, including formal,
informal, and covariance models, with 'UCINET'-aligned consensus extraction.

On win-builder, the final `R-devel` check completed with 1 NOTE in
`checking CRAN incoming feasibility`:

- `New submission`
- possible misspellings in `DESCRIPTION`: `Batchelder`, `UCINET`

These are expected and harmless. A previous external-URL SSL note from the
UCINET website was resolved by changing the README links from `https` to
`http` before the final win-builder run.

## Test environments

- Local macOS check: macOS Tahoe 26.4.1, R 4.5.2
- `R CMD check --as-cran` on `Romney_0.1.0.tar.gz`
- win-builder submission sent to `R-devel` on 2026-05-10; results are sent to the maintainer email by win-builder

## R CMD check results

0 errors | 0 warnings | 3 notes

Notes:

- `New submission`
- `README.md`/`NEWS.md` cannot be checked without `pandoc` installed on the local machine
- HTML validation note due to local `tidy` version not being recent enough on the local machine

These notes are unrelated to package functionality.

## Resubmission

This is a new submission.

## Comments

`Romney` provides classical cultural consensus analysis in R, including formal,
informal, and covariance models, with UCINET-aligned consensus extraction.

At the time this file was prepared, the win-builder upload had completed
successfully and the detailed Windows check results were still pending by
email.

## Development Status

Draft for a future 0.1.1 submission. This update has not been submitted to
CRAN. The historical win-builder results for 0.1.0 do not validate 0.1.1.

## Test Environment

- Local macOS 27.0.1, aarch64, R 4.5.2, psych 2.6.3.
- `R CMD check --as-cran` on `Romney_0.1.1.tar.gz`, October 9, 2026.
- Examples, testthat tests, vignette rebuilding, and PDF manual compilation.

## Check Results

0 errors | 0 warnings | 1 local NOTE.

The HTML-validation check is skipped because the local HTML Tidy version
is too old and the optional V8 package is unavailable for math-rendering
validation. The vignette and PDF manual build successfully. This note
describes local check-tool limitations, not a known package failure.

## Changes

- Correct formal multiple-choice likelihoods and knowledge/guessing simulation.
- Preserve signed loadings and report invalid estimates and extraction failures.
- Add explicitly labelled weighted binary and informal answer keys.
- Expand input validation, mathematical tests and complete UCINET comparisons.
- Add scholarly documentation, references, citation metadata and the author's ORCID.

UCINET 6.832 reference comparisons cover all agreement cells, competence
scores, item answers and categorical frequency tables. Categorical answer
keys match exactly; ordinal means differ by less than 0.001. Small factor
and competence discrepancies are reported explicitly, including the
approximately 1.85% difference in the ordinal first-to-second factor ratio.

## Before Submission

Fresh Windows and Linux checks remain to be run. A five-configuration
GitHub Actions workflow is prepared but has not run for this unpublished
update. Obtain current win-builder results before replacing this draft
with submission-ready comments. Review NEWS for deliberate behavior
changes, including NA keys for ambiguous items and strict handling of
out-of-range competence.

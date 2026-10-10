# Romney 0.1.1 (development)

## Statistical Corrections

* Correct the formal multiple-choice likelihood: each individual incorrect
  category has probability `(1 - competence) / n_answers`. This changes
  posterior probabilities and can change keys outside the reference datasets.
* Correct formal simulation to include the true answer among guessed options
  and remove the binary `sample()` singleton bias.
* Retain signed factor loadings in competence estimates and mean-competence
  diagnostics instead of silently clipping all factors to [0, 1].
* Report factor-extraction failures rather than substituting eigen decomposition.

## Answer Keys And Diagnostics

* Add explicitly labelled binary weighted votes and original-scale informal
  weighted means. These are not Bayesian posterior probabilities.
* Add declared response categories, including unobserved options, to `consensus()`.
* Return NA keys for ties, no-data items and impossible formal posteriors;
  attach item statuses rather than choosing the first category arbitrarily.
* Default to skipping formal/covariance keys with out-of-range competence.
  Explicit `competence_policy = "truncate"` affects only answer-key weights.
* Add `factor_ss_loadings`, retaining `eigenvalues` as a compatibility alias.
  Keep raw matrix eigenvalues separate, and retain extraction warnings,
  residuals, communalities and pairwise observation counts in diagnostics.
* Do not apply the probability-scale mean-competence threshold to informal data.

## Validation And Documentation

* Validate dimensions, finite inputs, integer parameters, response levels,
  priors, overlap and undefined correlations before estimation.
* Preserve the caller's random-number state when simulation uses an explicit seed.
* Expand mathematical, simulation and complete UCINET-table regression tests.
* Add a methods vignette, function examples and references, a citation file,
  reproducible comparison tables, and package-check CI.
* Add the maintainer's ORCID to DESCRIPTION.
* Prevent reference-data imports from overwriting benchmark CSVs, and fix
  DL export directives that could consume a response as an embedded row label.

# Romney 0.1.0

* Initial CRAN release of the formal, informal and covariance agreement
  procedures, minimum-residual extraction and formal answer-key estimation.

# Romney

`Romney` is an R package for cultural consensus analysis.

It currently includes:

- formal consensus analysis for multiple-choice and binary data
- informal consensus analysis for interval and ordinal data
- covariance-model consensus analysis for binary data
- UCINET-aligned minimum-residual factor extraction for consensus diagnostics

## Installation

```r
# install.packages("pak")
pak::pak("wernerhertzog/Romney")
```

## Example

```r
library(Romney)

x <- simulate_consensus_data(
  n_respondents = 20,
  n_questions = 40,
  n_answers = 4,
  competence = 0.75,
  seed = 1
)

fit <- consensus(x$responses, method = "formal")
print(fit)
fit$answer_key$key[1:10]
```

## Included Comparison Files

The package ships with the current synthetic CSV comparison datasets and the
latest UCINET output logs in `inst/extdata`.

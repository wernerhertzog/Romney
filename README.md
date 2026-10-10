# Romney: Classical Cultural Consensus Analysis

[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/last-month/Romney)](https://CRAN.R-project.org/package=Romney)

`Romney` is an R package for classical cultural consensus analysis (CCA).
It provides three classical agreement procedures:

- the formal model for multiple-choice data
- the informal model for ordinal or interval data
- the covariance model for binary yes/no data

The basic idea of cultural consensus analysis is simple:
if a group shares a common cultural model, then people who know more of that
shared culture should agree with one another more often. From patterns of
agreement alone, we can estimate:

- whether response patterns are consistent with a single shared cultural model
- each respondent's cultural competence
- the culturally most likely answer for each item

The included reference datasets have been compared with
[`UCINET`](http://www.analytictech.com/ucinet/) 6.832. Agreement matrices match
at its printed precision; competence estimates and factor statistics are
close, but not identical. Complete comparison results are reported below.
[`ANTHROPAC`](http://www.analytictech.com/anthropac/anthropac.htm) belongs to
the same classical consensus tradition, but this repository does not contain
an independent ANTHROPAC validation run.

This checkout describes development version **0.1.1**. The published CRAN
version remains 0.1.0 until the maintainer releases this update.

## Installation

```r
install.packages("Romney")
```

To install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("wernerhertzog/Romney")
```

## What Classical CCA Does

In the classical approach introduced by Romney, Weller, and Batchelder,
we begin with a respondent-by-item matrix. Each row is a person and each
column is a question, item, rating, or judgment. The analysis then:

1. computes agreement among respondents
2. extracts the main latent dimension of agreement
3. interprets the first factor loading as cultural competence
4. uses those competences to estimate an answer key appropriate to the model

When there is one dominant shared cultural model, the first eigenvalue should
be much larger than the second, and first-factor competences should mostly be
positive.

## The Three Models

### 1. Formal Model

Use the formal model when each item has a discrete set of possible answers and
respondents choose one answer per item.

Typical data:

- multiple-choice survey questions with 3, 4, or 5 options
- binary true/false or yes/no items treated as 2-choice questions
- coded ethnographic responses where each item falls into one category

Examples:

- 36 respondents classify 103 foods as `hot` or `cold`
- respondents choose which of four plants is best for treating a symptom
- respondents identify which kin term applies in a given vignette

For two respondents $i$ and $j$, let $p_{ij}$ be the proportion of
items on which they gave the same answer, and let $m$ be the number of
possible response options. The formal model uses a guessing-corrected
agreement score:

$$
a_{ij} = \frac{m p_{ij} - 1}{m - 1}
$$

Why this matters: if there are many response options, some agreement is
expected by chance. The formal model corrects for that.

Under the formal model, a respondent knows an answer with probability $c_i$;
otherwise they guess uniformly among the $m$ possible options, including the
correct one. A matching response therefore has likelihood
$c_i + (1-c_i)/m$, while each particular non-matching response has likelihood
$(1-c_i)/m$. `answerkey_formal()` combines these likelihoods with an answer
prior to obtain posterior probabilities and the most probable answer.
These probabilities condition on estimated competence; they do not account
for uncertainty in the competence estimates themselves.

Specify `answer_levels` when not every allowable option appears in the data.
The present formal model assumes the same response options for every item.

### 2. Informal Model

Use the informal model when responses are ordered or numeric rather than
categorically correct/incorrect.

Typical data:

- Likert-type ratings such as 1 to 5 agreement scales
- severity ratings, importance ratings, or preference ratings
- ordinal rankings coded numerically

Examples:

- respondents rate how "hot" each food is on a 1 to 5 scale
- people rank medicinal plants by perceived effectiveness
- participants rate how appropriate different behaviors are in a situation

Here, agreement is not about exact matches in categories. Instead, it is about
whether respondents vary together across items. The usual agreement measure is
the correlation between respondents:

$$
a_{ij} = \mathrm{cor}(x_i, x_j)
$$

where $x_i$ and $x_j$ are the vectors of responses given by respondents
$i$ and $j$.

In plain language: if two people place items in a similar order, or give
similarly high and low ratings across items, they are in stronger consensus.

`answerkey_informal()` returns a competence-weighted mean response for each
item, omitting missing responses and retaining signed weights. These means
are expressed in the original response units, not as standardized regression
factor scores. Informal loadings describe correspondence with the shared
response pattern; they are not probabilities of knowing an answer.

Pearson correlation treats numeric rank or rating codes as scores. The
analysis is not invariant to arbitrary recoding of an ordinal scale, and
this implementation does not substitute Spearman correlations or a separate
ordinal-response model.

### 3. Covariance Model

Use the covariance model when the data are binary yes/no or true/false and you
want the classical binary consensus model used in UCINET.

Typical data:

- yes/no judgments
- present/absent coding
- true/false statements

Examples:

- whether each food is classified as hot or cold
- whether a plant is considered medicinal
- whether a behavior is considered acceptable or unacceptable

For each pair of respondents, the binary data can be summarized in a $2 \times 2$
table with counts $n_{11}$, $n_{10}$, $n_{01}$, and $n_{00}$. The
covariance model uses a covariance-style agreement score:

$$
a_{ij} =
\frac{n_{11} n_{00} - n_{10} n_{01}}
     {n (n - 1)\pi(1-\pi)}
$$

where $n$ is the number of jointly observed items used for that pair and
$\pi$ is the assumed proportion of "yes" or "true" items in the unknown
answer key, not simply the observed proportion of respondents saying yes.

The covariance approach addresses response bias in competence estimation,
but remains sensitive to the assumed answer-key proportion. A value of 0.5
is the default, not a guarantee that an unbalanced domain or a biased answer
key has been adequately modeled. `answerkey_covariance()` supplies a
competence-weighted binary vote. Its weighted proportions are descriptive,
not Bayesian posterior probabilities or estimates of response-bias parameters.

## How To Read The Output

The main outputs of classical consensus analysis are:

- an agreement matrix among respondents
- competence scores for each respondent
- the first and second factor sums of squared loadings, and their ratio
- an estimated cultural answer key

A common rule of thumb is that a strong one-culture solution has:

- a first-to-second eigenvalue ratio greater than about 3
- few or no negative first-factor competences

These are heuristics, not hypothesis tests or proof that one cultural model
exists. The independence of informants, coherence of the cultural domain,
and plausibility of a shared answer key also require substantive assessment.

`competence` retains signed factor loadings. Negative or out-of-range
first-factor estimates are flagged, not silently replaced by zero or one.
For formal and covariance analyses, the default `competence_policy = "strict"`
does not estimate an answer key from invalid probability-scale loadings.
Explicit truncation is available for sensitivity analysis, but does not
repair a poorly fitting model. Higher factors are dimensions of variation,
not automatically separate cultural groups.

For backward compatibility, `eigenvalues` remains an output field, but
contains factor sums of squared loadings, also named `factor_ss_loadings`.
`raw_eigenvalues` contains eigenvalues of the original agreement matrix.
The two quantities should not be conflated. Factor-extraction errors now
stop the analysis rather than silently change estimators.

Missing responses are excluded pairwise. This can produce a non-positive-
semidefinite agreement matrix; inspect `diagnostics$positive_semidefinite`
and retained factor warnings. Unobserved items, ties, and impossible formal
posteriors have `NA` keys with an explanatory item status.

## UCINET Reproduction

The repository includes three fixed synthetic datasets, each with 36
respondents and 103 items, and their UCINET 6.832 output logs from May 9, 2026:

- synthetic multiple-choice, binary, and ordinal datasets in CSV format
- the original `UCINET` result logs used for comparison
- a reproducible script that compares complete available output tables

The following comparison uses R 4.5.2, `psych` 2.6.3, and development
version 0.1.1 of `Romney`. "Factor 1" and "Factor 2" below refer to the
statistics labelled eigenvalues by UCINET.

| Model | Factor 1: Romney / UCINET | Factor 2: Romney / UCINET | Maximum competence difference | Answer-key comparison |
| --- | --- | --- | --- | --- |
| Binary covariance | 8.967573 / 8.944 | 1.128306 / 1.126 | 0.006893 | 103 of 103 identical |
| Multiple choice | 12.685598 / 12.671 | 0.663355 / 0.661 | 0.004021 | 103 of 103 identical |
| Informal ordinal | 27.394070 / 27.383 | 0.451097 / 0.443 | 0.005870 | Maximum absolute difference 0.000744 |

All 36 competence scores, 103 answers, and 1,296 agreement-matrix cells per
dataset are checked. Agreement differences are below 0.0005, consistent with
UCINET's three-decimal output. All raw item frequencies match exactly.
The largest weighted-frequency differences are 0.036901 for binary data and
0.017003 for multiple-choice data; these tables use a normalized total of
36 respondents even when an item has missing responses.

The small factor differences remain genuine numerical discrepancies, not
just printed rounding. In particular, the ordinal factor ratio is 60.727650
in Romney and 61.871 in UCINET: a small difference in the second factor is
amplified by division. No benchmark-specific numerical adjustment is applied.
The logs contain no posterior-probability tables or second-factor loading
tables, so those quantities are not claimed to have independent UCINET
validation. Formal posterior probabilities are tested against independent
mathematical calculations.

From the package source directory, regenerate the CSV comparisons with:

```sh
Rscript --vanilla data-raw/compare_ucinet.R
```

[Full comparison tables and methodology](inst/validation/README.md) include
input checksums and software versions. The reference CSVs are preserved,
not regenerated by the corrected simulator. They are test fixtures, not
ethnographic observations; their original simulation seeds are not recorded
in the published repository.

## Minimal Example

```r
library(Romney)

x <- simulate_consensus_data(
  n_respondents = 20,
  n_questions = 40,
  n_answers = 4,
  competence = 0.75,
  seed = 1
)

fit <- consensus(x$responses, method = "formal", answer_levels = 1:4)

print(fit)
fit$competence[1:5, 1]
fit$answer_key$key[1:10]
```

The [methods vignette](vignettes/classical-consensus.Rmd) explains the models,
assumptions, and output in more detail. After installing version 0.1.1, use
`vignette("classical-consensus", package = "Romney")` and
`citation("Romney")` for the package citation.

## References

- [Romney, A. K., Weller, S. C., & Batchelder, W. H. (1986). Culture as consensus: A theory of culture and informant accuracy. *American Anthropologist, 88*(2), 313-338.](https://doi.org/10.1525/aa.1986.88.2.02a00020)
- [Romney, A. K., Batchelder, W. H., & Weller, S. C. (1987). Recent Applications of Cultural Consensus Theory. *American Behavioral Scientist, 31*(2), 163-177.](https://doi.org/10.1177/000276487031002003)
- [Weller, S. C. (2007). Cultural consensus theory: Applications and frequently asked questions. *Field Methods, 19*(4), 339-368.](https://doi.org/10.1177/1525822X07303502)

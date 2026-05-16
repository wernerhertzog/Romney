# Romney: Classical Cultural Consensus Analysis

`Romney` is an R package for classical cultural consensus analysis (CCA).
It implements the three core models most researchers mean when they talk
about "classical" consensus analysis:

- the formal model for multiple-choice data
- the informal model for ordinal or interval data
- the covariance model for binary yes/no data

The basic idea of cultural consensus analysis is simple:
if a group shares a common cultural model, then people who know more of that
shared culture should agree with one another more often. From patterns of
agreement alone, we can estimate:

- whether there is a single shared cultural model
- each respondent's cultural competence
- the culturally most likely answer for each item

This package reproduces the classical consensus results from
['UCINET'](http://www.analytictech.com/ucinet/) on the included comparison
datasets, including the 'UCINET'-style consensus eigensystem used in its
[Consensus Analysis help page](http://www.analytictech.com/ucinet/help/hs2900.htm).
For the classical consensus procedures covered here, this also aligns with
['ANTHROPAC'](https://www.analytictech.com/anthropac/anthropac.htm), which
reports the same results as 'UCINET' for these analyses.

## Installation

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
4. uses those competences to estimate the culturally most likely answers

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

The estimated answer key is then built by weighting respondents by their
estimated competence, so more culturally knowledgeable respondents count more.

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

The estimated cultural answer key for informal data is typically the
competence-weighted mean response for each item.

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

where $n$ is the number of non-missing items used for that pair and
$\pi$ is the prior proportion of "yes" or "true" responses.

Why use this instead of the formal model for binary data? Because some binary
domains are highly unbalanced. If most items are "no," then raw agreement can
look high even when respondents are not very informative. The covariance model
handles that more carefully.

## How To Read The Output

The main outputs of classical consensus analysis are:

- an agreement matrix among respondents
- competence scores for each respondent
- the first and second eigenvalues, and their ratio
- an estimated cultural answer key

A common rule of thumb is that a strong one-culture solution has:

- a first-to-second eigenvalue ratio greater than about 3
- few or no negative first-factor competences

These are diagnostics, not magical thresholds, but they are the standard
classical starting point.

## UCINET Reproduction

`Romney` is built to reproduce the classical consensus results reported by
'UCINET' as closely as possible. In this repository, the package includes:

- synthetic multiple-choice, binary, and ordinal datasets in CSV format
- the latest 'UCINET' result logs used for comparison
- helper scripts used to regenerate the comparisons

The current implementation uses 'UCINET'-aligned minimum-residual factor
extraction for the consensus eigensystem, which is why the eigenvalues,
competence estimates, and answer keys closely track 'UCINET' on the same data.
Because 'UCINET' and 'ANTHROPAC' implement the same classical consensus
procedures, these comparisons also support agreement with 'ANTHROPAC' for the
models covered by this package.

If you already use 'UCINET' or 'ANTHROPAC', this package is meant to give you the same
classical workflow directly in R.

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

fit <- consensus(x$responses, method = "formal")

print(fit)
fit$competence[1:5, 1]
fit$answer_key$key[1:10]
```

## References

- [Romney, A. K., Weller, S. C., & Batchelder, W. H. (1986). Culture as consensus: A theory of culture and informant accuracy. *American Anthropologist, 88*(2), 313-338.](https://doi.org/10.1525/aa.1986.88.2.02a00020)
- [Romney, A. K., Batchelder, W. H., & Weller, S. C. (1987). Recent Applications of Cultural Consensus Theory. *American Behavioral Scientist, 31*(2), 163-177.](https://doi.org/10.1177/000276487031002003)
- [Weller, S. C. (2007). Cultural consensus theory: Applications and frequently asked questions. *Field Methods, 19*(4), 339-368.](https://doi.org/10.1177/1525822X07303502)

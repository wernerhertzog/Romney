# Romney: Classical Cultural Consensus Analysis

[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/last-month/Romney)](https://CRAN.R-project.org/package=Romney)

`Romney` is an R package for classical cultural consensus analysis (CCA).
It implements three models:

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

## Installation

```r
install.packages("Romney")
```

To install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("wernerhertzog/Romney")
```

Version 0.1.1 is under development and has not yet been released on CRAN.

## What Classical CCA Does

In the classical approach introduced by Romney, Weller, and Batchelder,
we begin with a respondent-by-item matrix. Each row is a person and each
column is a question, item, rating, or judgment. The analysis then:

1. computes agreement among respondents
2. extracts the main latent dimension of agreement
3. interprets the first factor loading as cultural competence
4. uses those competences to estimate an answer key appropriate to the model

When there is one dominant shared cultural model, the first factor should
be much stronger than the second, and first-factor competences should mostly
be positive.

## The Three Models

### 1. Formal Model

Use the formal model when each item has a discrete set of possible answers and
respondents choose one answer per item.

Examples:

- respondents classify foods as `hot` or `cold`
- respondents choose which of four plants is best for treating a symptom
- respondents identify which kin term applies in a given vignette

For two respondents $i$ and $j$, let $p_{ij}$ be the proportion of
items on which they gave the same answer, and let $m$ be the number of
possible response options. The formal model uses a guessing-corrected
agreement score:

$$
a_{ij} = \frac{m p_{ij} - 1}{m - 1}
$$

The model assumes that respondents either know an answer or guess uniformly
among the possible options. It uses estimated competence to calculate the
probability of each answer and select the most probable cultural answer key.

### 2. Informal Model

Use the informal model when responses are ordered or numeric rather than
categorically correct/incorrect.

Examples:

- respondents rate how "hot" each food is on a 1 to 5 scale
- people rank medicinal plants by perceived effectiveness
- participants rate how appropriate different behaviors are in a situation

Here, agreement is not about exact matches in categories. Instead, it is about
whether respondents vary together across items. Agreement is measured by
Pearson correlation between respondents:

$$
a_{ij} = \mathrm{cor}(x_i, x_j)
$$

where $x_i$ and $x_j$ are the vectors of responses given by respondents
$i$ and $j$.

In plain language: if two people place items in a similar order, or give
similarly high and low ratings across items, they are in stronger consensus.

The estimated cultural answer key is the competence-weighted mean response
for each item. Here, competence measures agreement with the shared response
pattern rather than the probability of knowing an answer.

### 3. Covariance Model

Use the covariance model when the data are binary yes/no or true/false and you
want the classical binary covariance procedure used in `UCINET`.

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
$\pi$ is the assumed proportion of "yes" or "true" items in the cultural
answer key. The default is 0.5.

Unlike exact-match agreement, covariance takes account of each respondent's
tendency to say yes or no. The answer key is estimated by a competence-weighted
vote for each item.

## How To Read The Output

The main outputs of classical consensus analysis are:

- an agreement matrix among respondents
- competence scores for each respondent
- the first and second factor sums of squared loadings, and their ratio
- an estimated cultural answer key

A common rule of thumb is that a strong one-culture solution has:

- a first-to-second factor ratio greater than about 3
- few or no negative first-factor competences

These are guidelines, not proof of a single shared culture. Interpretation
also depends on the cultural domain and the study's ethnographic context.

The factor statistics are sums of squared loadings, called "eigenvalues" in
`UCINET`. They are distinct from the eigenvalues of the original agreement
matrix.

## UCINET Reproduction

On the three included synthetic datasets, `Romney` closely reproduces the
classical consensus results from [`UCINET`](http://www.analytictech.com/ucinet/)
6.832. Agreement matrices match at its printed precision, categorical answer
keys match exactly, and ordinal answer estimates differ by less than 0.001.
Small differences remain in competence estimates and factor statistics.

The repository includes the CSV datasets, original `UCINET` logs, and scripts
for repeating the comparisons. See the [validation report](inst/validation/README.md)
for the full results and methodology.

The models follow the classical consensus framework also implemented in
[`ANTHROPAC`](http://www.analytictech.com/anthropac/anthropac.htm).

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

See the [methods vignette](vignettes/classical-consensus.Rmd) for details on
the models, assumptions, and diagnostics. Use `citation("Romney")` for the
package citation.

## References

- [Romney, A. K., Weller, S. C., & Batchelder, W. H. (1986). Culture as consensus: A theory of culture and informant accuracy. *American Anthropologist, 88*(2), 313-338.](https://doi.org/10.1525/aa.1986.88.2.02a00020)
- [Romney, A. K., Batchelder, W. H., & Weller, S. C. (1987). Recent Applications of Cultural Consensus Theory. *American Behavioral Scientist, 31*(2), 163-177.](https://doi.org/10.1177/000276487031002003)
- [Weller, S. C. (2007). Cultural consensus theory: Applications and frequently asked questions. *Field Methods, 19*(4), 339-368.](https://doi.org/10.1177/1525822X07303502)

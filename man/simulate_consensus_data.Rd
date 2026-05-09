\name{simulate_consensus_data}
\alias{simulate_consensus_data}
\title{Simulate Formal Consensus Data}
\usage{
simulate_consensus_data(
  n_respondents,
  n_questions,
  n_answers = 2,
  competence = 0.7,
  seed = NULL
)
}
\arguments{
  \item{n_respondents}{Number of respondents.}
  \item{n_questions}{Number of questions/items.}
  \item{n_answers}{Number of possible answers per item.}
  \item{competence}{Scalar or vector of respondent competences.}
  \item{seed}{Optional random seed.}
}
\value{
A list with \code{responses}, \code{key}, and \code{competence}.
}
\description{
Simulate respondent-by-item response data for the formal consensus model.
}

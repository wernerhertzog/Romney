\name{answerkey_formal}
\alias{answerkey_formal}
\title{Estimate a Formal Consensus Answer Key}
\usage{
answerkey_formal(data, competence, prior = NULL, answer_levels = NULL)
}
\arguments{
  \item{data}{A respondent-by-item matrix or data frame.}
  \item{competence}{Numeric competence scores, one per respondent.}
  \item{prior}{Optional prior distribution over answer levels.}
  \item{answer_levels}{Optional ordered vector of allowable answer levels.}
}
\value{
A list with \code{key}, \code{probabilities}, and \code{levels}.
}
\description{
Estimate the most likely answer key under the formal consensus model.
}

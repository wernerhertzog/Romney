\name{consensus}
\alias{consensus}
\alias{print.romney_consensus}
\title{Run a Cultural Consensus Analysis}
\usage{
consensus(
  data,
  cultures = 1,
  method = c("formal", "informal", "covariance"),
  prior = 0.5,
  return_answer_key = TRUE
)
}
\arguments{
  \item{data}{A respondent-by-item matrix or data frame.}
  \item{cultures}{Number of latent cultures to extract.}
  \item{method}{One of \code{"formal"}, \code{"informal"}, or \code{"covariance"}.}
  \item{prior}{Prior proportion of true items for the covariance model.}
  \item{return_answer_key}{Whether to estimate the answer key for the formal model.}
}
\value{
An object of class \code{romney_consensus}.
}
\description{
Run a cultural consensus analysis using UCINET-aligned minimum-residual
factor extraction for the consensus eigensystem.
}

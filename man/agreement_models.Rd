\name{agreement_models}
\alias{agreement_models}
\alias{agreement_formal}
\alias{agreement_informal}
\alias{agreement_covariance}
\title{Agreement Matrices for Consensus Analysis}
\usage{
agreement_formal(data, n_answers = NULL)

agreement_informal(data)

agreement_covariance(data, prior = 0.5)
}
\arguments{
  \item{data}{A respondent-by-item matrix or data frame.}
  \item{n_answers}{Number of possible answers for the formal model.}
  \item{prior}{Prior proportion of true items for the covariance model.}
}
\value{
A square agreement matrix.
}
\description{
Compute respondent-by-respondent agreement matrices for the formal,
informal, and covariance consensus models.
}

#' Estimate a formal consensus answer key
#'
#' @param data A respondent-by-item matrix or data frame.
#' @param competence Numeric competence scores, one per respondent.
#' @param prior Optional prior distribution over answer levels. Can be `NULL`,
#'   a vector of answer-level priors, or a matrix with one column per item.
#' @param answer_levels Optional ordered vector of allowable answer levels.
#'
#' @details For candidate answer \eqn{k}, a matching response has likelihood
#'   \eqn{c_i + (1-c_i)/m}; each specific non-matching response has likelihood
#'   \eqn{(1-c_i)/m}. Posterior probabilities condition on the supplied
#'   competence estimates; they do not include uncertainty in those estimates.
#'   Computation uses log likelihoods. Ties within \eqn{10^{-12}}, entirely
#'   missing items, and impossible observations have \code{NA} answer keys.
#'   Missing items retain their prior distribution. If every candidate has
#'   zero likelihood, probabilities are \code{NA} and a warning is issued.
#'   Weighted frequencies are separate descriptive quantities, not posteriors.
#' @return A list with \code{key}, \code{probabilities}, \code{levels},
#'   \code{status}, normalized \code{prior}, \code{weighted_proportions}, and
#'   \code{weighted_frequencies}.
#'   Status is \code{estimated}, \code{tie}, \code{no_data}, or
#'   \code{impossible}. Weighted frequencies are proportions multiplied by the
#'   total number of respondents, matching the scale of 'UCINET' detail tables.
#' @references Romney, A. K., Weller, S. C., and Batchelder, W. H. (1986).
#'   Culture as consensus: A theory of culture and informant accuracy.
#'   American Anthropologist, 88(2), 313--338. \doi{10.1525/aa.1986.88.2.02a00020}.
#' @examples
#' x <- matrix(c("A", "A", "B"), ncol = 1)
#' answerkey_formal(x, c(0.8, 0.7, 0.2), answer_levels = LETTERS[1:4])
#' @export
answerkey_formal <- function(data, competence, prior = NULL, answer_levels = NULL) {
  data <- .as_matrix(data)
  qn <- .question_names(data)

  competence <- .check_competence(competence, nrow(data))
  answer_levels <- .check_levels(data, answer_levels)

  n_answers <- length(answer_levels)
  n_questions <- ncol(data)
  if (n_answers < 2) {
    stop("Need at least 2 answer levels.", call. = FALSE)
  }

  if (is.null(prior)) {
    prior <- matrix(1 / n_answers, nrow = n_answers, ncol = n_questions)
  } else if (is.vector(prior)) {
    if (!is.numeric(prior) || is.complex(prior) || length(prior) != n_answers) {
      stop("Vector `prior` must have length equal to number of answer levels.", call. = FALSE)
    }
    prior <- matrix(prior, nrow = n_answers, ncol = n_questions)
  } else if (is.matrix(prior)) {
    if (!is.numeric(prior) || is.complex(prior) ||
        !all(dim(prior) == c(n_answers, n_questions))) {
      stop("Matrix `prior` must have dimensions n_answers x n_questions.", call. = FALSE)
    }
  } else {
    stop("`prior` must be NULL, a numeric vector, or a numeric matrix.", call. = FALSE)
  }

  if (any(prior < 0) || any(!is.finite(prior))) {
    stop("`prior` values must be finite and non-negative.", call. = FALSE)
  }

  col_max <- apply(prior, 2, max)
  if (any(col_max == 0)) {
    stop("Each prior column must have positive sum.", call. = FALSE)
  }
  prior <- sweep(prior, 2, col_max, "/")
  prior <- sweep(prior, 2, colSums(prior), "/")

  wrong <- (1 - competence) / n_answers
  right <- competence + wrong

  probs <- matrix(NA_real_, nrow = n_answers, ncol = n_questions)
  status <- rep("estimated", n_questions)
  for (j in seq_len(n_questions)) {
    obs <- data[, j]
    keep <- !is.na(obs)
    logp <- rep(NA_real_, n_answers)

    for (i in seq_len(n_answers)) {
      if (any(keep)) {
        lik <- ifelse(obs[keep] == answer_levels[i], right[keep], wrong[keep])
        logp[i] <- sum(log(lik)) + log(prior[i, j])
      } else {
        logp[i] <- log(prior[i, j])
      }
    }

    finite <- is.finite(logp)
    if (!any(finite)) {
      p <- rep(NA_real_, n_answers)
      status[j] <- "impossible"
    } else {
      m <- max(logp[finite])
      p <- exp(logp - m)
      p[!finite] <- 0
      p <- p / sum(p)
    }
    if (!any(keep)) status[j] <- "no_data"
    probs[, j] <- p
  }
  rownames(probs) <- as.character(answer_levels)
  colnames(probs) <- qn
  selected <- .key_from_scores(probs, answer_levels, status)
  if (any(status == "impossible")) {
    warning(sprintf("%d item(s) have zero likelihood under every candidate answer.",
                    sum(status == "impossible")), call. = FALSE)
  }
  votes <- .categorical_votes(data, competence, answer_levels)
  list(key = selected$key, probabilities = probs, levels = answer_levels, prior = prior,
       status = selected$status, weighted_proportions = votes$weighted_proportions,
       weighted_frequencies = votes$weighted_frequencies)
}

#' Estimate a binary competence-weighted answer key
#'
#' @param data A respondent-by-item matrix or data frame with two response values.
#' @param competence Finite competence scores in \eqn{[0,1]}, one per respondent.
#' @param answer_levels Optional vector specifying the two allowable responses.
#' @details Each observed response contributes its respondent's competence to
#'   the corresponding category. The category with the greater total weight is
#'   selected. Missing responses are omitted, and weights are normalized within
#'   each item. Ties within \eqn{10^{-12}}, entirely missing items, and items
#'   with zero total weight have \code{NA} keys. This is a weighted vote, not a
#'   posterior probability calculation or an estimate of respondent response bias.
#' @return A list with \code{key}, \code{levels}, \code{status},
#'   \code{weighted_proportions}, and \code{weighted_frequencies}. Frequencies
#'   are proportions multiplied by the total number of respondents, as in
#'   'UCINET' detail tables. Status may also be \code{zero_weight}.
#' @references Weller, S. C. (2007). Cultural consensus theory: Applications and
#'   frequently asked questions. Field Methods, 19(4), 339--368.
#'   \doi{10.1177/1525822X07303502}.
#' @examples
#' answerkey_covariance(matrix(c(0, 1, 1), ncol = 1), c(0.2, 0.8, 0.7))
#' @export
answerkey_covariance <- function(data, competence, answer_levels = NULL) {
  data <- .as_matrix(data)
  competence <- .check_competence(competence, nrow(data))
  levels <- .check_levels(data, answer_levels)
  if (length(levels) != 2L) {
    stop("Covariance answer keys require exactly two answer levels.", call. = FALSE)
  }
  out <- .categorical_votes(data, competence, levels)
  out$levels <- levels
  out
}

#' Estimate an informal competence-weighted answer key
#'
#' @param data A numeric respondent-by-item matrix or data frame.
#' @param competence Finite signed factor loadings, one per respondent.
#' @details Returns \eqn{\sum_i c_i x_{ij} / \sum_i c_i} over observed responses
#'   to each item. Signed weights are retained. A non-positive total weight or
#'   an entirely missing item produces an \code{NA} key. Negative weights can
#'   yield means outside the observed response range and warrant scrutiny of
#'   the single-culture assumption. These means are in the original response
#'   units; they are not standardized regression factor scores or posterior
#'   probabilities. Agreement uses Pearson correlations, so numeric coding
#'   of ordinal responses affects the analysis.
#' @return A list with numeric \code{key}, \code{status}, and \code{weight_sum}.
#' @references Romney, A. K., Batchelder, W. H., and Weller, S. C. (1987).
#'   Recent applications of cultural consensus theory. American Behavioral
#'   Scientist, 31(2), 163--177. \doi{10.1177/000276487031002003}.
#' @examples
#' answerkey_informal(rbind(c(1, 4), c(2, 5)), c(0.8, 0.4))
#' @export
answerkey_informal <- function(data, competence) {
  data <- .as_matrix(data)
  if (!is.numeric(data)) stop("`data` must be numeric for informal answer keys.", call. = FALSE)
  competence <- .check_competence(competence, nrow(data), probability = FALSE)
  keep <- !is.na(data)
  observed <- data
  observed[!keep] <- 0
  total <- colSums(sweep(keep, 1, competence, "*"))
  key <- rep(NA_real_, ncol(data))
  status <- ifelse(colSums(keep) == 0, "no_data", "zero_weight")
  valid <- total > 0 & colSums(keep) > 0
  key[valid] <- colSums(sweep(observed, 1, competence, "*"))[valid] / total[valid]
  status[valid] <- "estimated"
  names(key) <- names(status) <- names(total) <- .question_names(data)
  list(key = key, status = status, weight_sum = total)
}

#' Estimate a formal consensus answer key
#'
#' @param data A respondent-by-item matrix or data frame.
#' @param competence Numeric competence scores, one per respondent.
#' @param prior Optional prior distribution over answer levels. Can be `NULL`,
#'   a vector of answer-level priors, or a matrix with one column per item.
#' @param answer_levels Optional ordered vector of allowable answer levels.
#'
#' @return A list with `key`, `probabilities`, and `levels`.
#' @export
answerkey_formal <- function(data, competence, prior = NULL, answer_levels = NULL) {
  data <- .as_matrix(data)
  qn <- .question_names(data)

  if (!is.numeric(competence) || length(competence) != nrow(data)) {
    stop("`competence` must be numeric and have one value per respondent.", call. = FALSE)
  }
  if (any(!is.finite(competence)) || any(competence < 0) || any(competence > 1)) {
    stop("All competence values must be finite and in [0, 1].", call. = FALSE)
  }

  if (is.null(answer_levels)) {
    answer_levels <- .answer_levels(data)
  }

  n_answers <- length(answer_levels)
  n_questions <- ncol(data)
  if (n_answers < 2) {
    stop("Need at least 2 answer levels.", call. = FALSE)
  }

  if (is.null(prior)) {
    prior <- matrix(1 / n_answers, nrow = n_answers, ncol = n_questions)
  } else if (is.vector(prior)) {
    if (!is.numeric(prior) || length(prior) != n_answers) {
      stop("Vector `prior` must have length equal to number of answer levels.", call. = FALSE)
    }
    prior <- matrix(prior, nrow = n_answers, ncol = n_questions)
  } else if (is.matrix(prior)) {
    if (!all(dim(prior) == c(n_answers, n_questions))) {
      stop("Matrix `prior` must have dimensions n_answers x n_questions.", call. = FALSE)
    }
  } else {
    stop("`prior` must be NULL, a numeric vector, or a numeric matrix.", call. = FALSE)
  }

  if (any(prior < 0) || any(!is.finite(prior))) {
    stop("`prior` values must be finite and non-negative.", call. = FALSE)
  }

  col_sums <- colSums(prior)
  if (any(col_sums == 0)) {
    stop("Each prior column must have positive sum.", call. = FALSE)
  }
  prior <- sweep(prior, 2, col_sums, "/")

  wrong <- (1 - competence) * (n_answers - 1) / n_answers
  right <- 1 - wrong

  probs <- matrix(NA_real_, nrow = n_answers, ncol = n_questions)
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
      p <- prior[, j]
    } else {
      m <- max(logp[finite])
      p <- exp(logp - m)
      p[!finite] <- 0
      p <- p / sum(p)
    }
    probs[, j] <- p
  }

  key_idx <- apply(probs, 2, which.max)
  key <- answer_levels[key_idx]
  names(key) <- qn
  rownames(probs) <- as.character(answer_levels)
  colnames(probs) <- qn

  list(key = key, probabilities = probs, levels = answer_levels)
}

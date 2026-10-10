#' Agreement matrices for consensus analysis
#'
#' Compute respondent-by-respondent agreement matrices for the formal,
#' informal, and covariance consensus models.
#'
#' @param data A respondent-by-item matrix or data frame.
#' @param n_answers Number of possible answers for the formal model, including
#'   options that were not observed. All items must have the same options.
#' @param prior Prior proportion of true items for the covariance model.
#' @param answer_levels Optional vector of the two allowable binary responses.
#'
#' @details Missing responses are excluded pairwise, not imputed. Formal
#'   agreement is \eqn{(m p_{ij} - 1)/(m - 1)}, where \eqn{p_{ij}} is the
#'   proportion of matching responses and \eqn{m} is the number of choices.
#'   Informal agreement uses Pearson correlations of respondent profiles.
#'   Numeric rank codes are treated as scores; arbitrary ordinal recoding is
#'   not invariant under Pearson correlation. Covariance agreement divides the
#'   sample covariance of binary profiles by \eqn{\pi(1-\pi)}. The second allowed
#'   response value (by default the higher sorted value) is treated as true.
#'   Diagonals are set to one
#'   as input to factor extraction; they are not estimates of competence.
#' @references Romney, A. K., Weller, S. C., and Batchelder, W. H. (1986).
#'   Culture as consensus: A theory of culture and informant accuracy.
#'   American Anthropologist, 88(2), 313--338. \doi{10.1525/aa.1986.88.2.02a00020}.
#'   Weller, S. C. (2007). Cultural consensus theory: Applications and frequently
#'   asked questions. Field Methods, 19(4), 339--368. \doi{10.1177/1525822X07303502}.
#' @examples
#' x <- rbind(c(0, 1, 1, 0), c(0, 1, 0, 0), c(1, 1, 1, 0))
#' agreement_formal(x, n_answers = 2)
#' agreement_covariance(x)
#' @return A square agreement matrix.
#' @name agreement_models
NULL

#' @rdname agreement_models
#' @export
agreement_formal <- function(data, n_answers = NULL) {
  data <- .as_matrix(data, min_respondents = 2L)
  rn <- .respondent_names(data)
  .pairwise_counts(data, minimum = 1L)

  if (is.null(n_answers)) {
    n_answers <- length(.answer_levels(data))
  }
  n_answers <- .check_integer(n_answers, "n_answers", minimum = 2L)
  if (length(unique(data[!is.na(data)])) > n_answers) {
    stop("`n_answers` cannot be smaller than the number of observed responses.", call. = FALSE)
  }

  n <- nrow(data)
  out <- matrix(NA_real_, n, n)

  for (i in seq_len(n)) {
    for (j in i:n) {
      xi <- data[i, ]
      xj <- data[j, ]
      keep <- !is.na(xi) & !is.na(xj)
      if (any(keep)) {
        p_match <- mean(xi[keep] == xj[keep])
        out[i, j] <- (n_answers * p_match - 1) / (n_answers - 1)
        out[j, i] <- out[i, j]
      }
    }
  }

  diag(out) <- 1
  rownames(out) <- rn
  colnames(out) <- rn
  out
}

#' @rdname agreement_models
#' @export
agreement_informal <- function(data) {
  data <- .as_matrix(data, min_respondents = 2L, min_questions = 2L)
  if (!is.numeric(data)) {
    stop("`data` must be numeric for the informal model.", call. = FALSE)
  }

  .pairwise_counts(data, minimum = 2L)
  if (any(apply(data, 1, stats::sd, na.rm = TRUE) == 0)) {
    stop("Informal agreement is undefined for constant respondent profiles.", call. = FALSE)
  }
  out <- suppressWarnings(stats::cor(t(data), use = "pairwise.complete.obs"))
  if (any(!is.finite(out))) {
    stop("Informal agreement is undefined: check variation on jointly observed items.", call. = FALSE)
  }
  rn <- .respondent_names(data)
  diag(out) <- 1
  rownames(out) <- rn
  colnames(out) <- rn
  out
}

#' @rdname agreement_models
#' @export
agreement_covariance <- function(data, prior = 0.5, answer_levels = NULL) {
  data <- .as_matrix(data, min_respondents = 2L, min_questions = 2L)
  .pairwise_counts(data, minimum = 2L)
  levels <- .check_levels(data, answer_levels)
  if (length(levels) != 2) {
    stop("Covariance model requires exactly 2 answer values.", call. = FALSE)
  }
  if (!is.numeric(prior) || is.complex(prior) || length(prior) != 1 ||
      !is.finite(prior) || prior <= 0 || prior >= 1) {
    stop("`prior` must be a single number between 0 and 1.", call. = FALSE)
  }

  bin <- matrix(ifelse(data == levels[2], 1, 0), nrow = nrow(data), ncol = ncol(data))
  bin[is.na(data)] <- NA_real_

  n <- nrow(bin)
  out <- matrix(NA_real_, n, n)

  for (i in seq_len(n)) {
    for (j in i:n) {
      xi <- bin[i, ]
      xj <- bin[j, ]
      keep <- !is.na(xi) & !is.na(xj)
      nk <- sum(keep)
      if (nk >= 2) {
        xi <- xi[keep]
        xj <- xj[keep]
        a <- sum(xi == 1 & xj == 1)
        b <- sum(xi == 1 & xj == 0)
        c <- sum(xi == 0 & xj == 1)
        d <- sum(xi == 0 & xj == 0)
        out[i, j] <- ((a * d) - (b * c)) / (nk * (nk - 1))
        out[j, i] <- out[i, j]
      }
    }
  }

  out <- out / (prior * (1 - prior))
  diag(out) <- 1
  rn <- .respondent_names(data)
  rownames(out) <- rn
  colnames(out) <- rn
  out
}

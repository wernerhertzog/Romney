#' Agreement matrices for consensus analysis
#'
#' Compute respondent-by-respondent agreement matrices for the formal,
#' informal, and covariance consensus models.
#'
#' @param data A respondent-by-item matrix or data frame.
#' @param n_answers Number of possible answers for the formal model.
#' @param prior Prior proportion of true items for the covariance model.
#'
#' @return A square agreement matrix.
#' @name agreement_models
NULL

#' @rdname agreement_models
agreement_formal <- function(data, n_answers = NULL) {
  data <- .as_matrix(data)
  rn <- .respondent_names(data)

  if (is.null(n_answers)) {
    n_answers <- length(.answer_levels(data))
  }
  if (!is.numeric(n_answers) || length(n_answers) != 1 || n_answers < 2) {
    stop("`n_answers` must be a single number >= 2.", call. = FALSE)
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
agreement_informal <- function(data) {
  data <- .as_matrix(data)
  if (!is.numeric(data)) {
    stop("`data` must be numeric for the informal model.", call. = FALSE)
  }

  out <- stats::cor(t(data), use = "pairwise.complete.obs")
  rn <- .respondent_names(data)
  diag(out) <- 1
  rownames(out) <- rn
  colnames(out) <- rn
  out
}

#' @rdname agreement_models
agreement_covariance <- function(data, prior = 0.5) {
  data <- .as_matrix(data)
  levels <- .answer_levels(data)
  if (length(levels) != 2) {
    stop("Covariance model requires exactly 2 answer values.", call. = FALSE)
  }
  if (!is.numeric(prior) || length(prior) != 1 || prior <= 0 || prior >= 1) {
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

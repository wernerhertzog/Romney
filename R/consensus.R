#' Run a cultural consensus analysis
#'
#' @param data A respondent-by-item matrix or data frame.
#' @param cultures Number of latent cultures to extract.
#' @param method One of `"formal"`, `"informal"`, or `"covariance"`.
#' @param prior Prior proportion of true items for the covariance model.
#' @param return_answer_key Whether to estimate the answer key for the formal
#'   model.
#'
#' @return An object of class `romney_consensus`.
#' @export
consensus <- function(
  data,
  cultures = 1,
  method = c("formal", "informal", "covariance"),
  prior = 0.5,
  return_answer_key = TRUE
) {
  data <- .as_matrix(data)
  method <- match.arg(method)

  if (!is.numeric(cultures) || length(cultures) != 1 || cultures < 1) {
    stop("`cultures` must be a single integer >= 1.", call. = FALSE)
  }
  cultures <- as.integer(cultures)

  agreement <- switch(
    method,
    formal = agreement_formal(data),
    informal = agreement_informal(data),
    covariance = agreement_covariance(data, prior = prior)
  )

  factor_fit <- .fit_consensus_factors(agreement, cultures = cultures)
  if (cultures > ncol(factor_fit$loadings)) {
    stop("`cultures` cannot exceed number of extracted factors.", call. = FALSE)
  }

  loadings <- factor_fit$loadings[, seq_len(cultures), drop = FALSE]
  rownames(loadings) <- .respondent_names(data)
  colnames(loadings) <- paste0("culture_", seq_len(cultures))

  for (k in seq_len(ncol(loadings))) {
    if (mean(loadings[, k], na.rm = TRUE) < 0) {
      loadings[, k] <- -loadings[, k]
    }
  }

  competence <- matrix(
    pmin(1, pmax(0, loadings)),
    nrow = nrow(loadings),
    ncol = ncol(loadings),
    dimnames = dimnames(loadings)
  )

  eigenvalues <- factor_fit$values
  ratio <- if (length(eigenvalues) >= 2 && is.finite(eigenvalues[2]) && eigenvalues[2] != 0) {
    eigenvalues[1] / eigenvalues[2]
  } else {
    Inf
  }

  mean_comp <- colMeans(competence, na.rm = TRUE)
  negative_first <- sum(loadings[, 1] < 0, na.rm = TRUE)
  criteria <- c(
    eigen_ratio_gt_3 = ratio > 3,
    mean_competence_gt_0_5 = mean_comp[1] > 0.5,
    no_negative_first_factor = negative_first == 0
  )

  answer <- NULL
  if (isTRUE(return_answer_key) && method == "formal") {
    answer <- answerkey_formal(data, competence = competence[, 1])
  }

  out <- list(
    method = method,
    cultures = cultures,
    agreement = agreement,
    eigenvalues = eigenvalues,
    raw_eigenvalues = factor_fit$raw_eigenvalues,
    factor_method = factor_fit$method,
    loadings = loadings,
    competence = competence,
    ratio_eigen_1_2 = ratio,
    mean_competence = mean_comp,
    negative_competence_first_factor = negative_first,
    criteria = criteria,
    criteria_met = sum(criteria),
    answer_key = answer
  )

  class(out) <- "romney_consensus"
  out
}

#' @export
print.romney_consensus <- function(x, ...) {
  cat("Consensus analysis (", x$method, ")\n", sep = "")
  cat("  first eigenvalue: ", round(x$eigenvalues[1], 3), "\n", sep = "")
  if (length(x$eigenvalues) >= 2) {
    cat("  second eigenvalue:", round(x$eigenvalues[2], 3), "\n")
    cat("  ratio 1/2:       ", round(x$ratio_eigen_1_2, 3), "\n", sep = "")
  }
  cat("  mean competence: ", round(x$mean_competence[1], 3), "\n", sep = "")
  cat("  negatives first: ", x$negative_competence_first_factor, "\n", sep = "")
  invisible(x)
}

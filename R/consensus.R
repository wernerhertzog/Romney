#' Run a cultural consensus analysis
#'
#' @param data A respondent-by-item matrix or data frame.
#' @param cultures Number of factor dimensions to return. Additional dimensions
#'   are not automatically distinct cultural groups.
#' @param method One of `"formal"`, `"informal"`, or `"covariance"`.
#' @param prior Prior proportion of true items for the covariance model.
#' @param return_answer_key Whether to estimate a first-factor answer key.
#' @param n_answers Optional number of possible responses for the formal model.
#' @param answer_levels Optional vector specifying all categorical response
#'   options, including unobserved options. Not used for the informal model.
#' @param competence_policy Policy for formal and covariance answer keys when
#'   first-factor loadings are outside \eqn{[0,1]}. \code{"strict"} (default) skips
#'   the key with a warning; \code{"truncate"} explicitly clips only answer-key
#'   weights. Reported competence and diagnostics always retain signed loadings.
#' @details Analysis requires at least three respondents and two items.
#'   At least two unrotated minimum-residual factors are extracted for the
#'   first-to-second factor ratio, even when only the first is returned.
#'   Extraction failures are errors, not substitutions of another estimator.
#'   The legacy \code{eigenvalues} field contains factor sums of squared
#'   loadings; \code{raw_eigenvalues} contains eigenvalues of the input agreement
#'   matrix. These are different quantities. Warnings and residuals are retained
#'   in \code{diagnostics}; convergence is not certified by a large ratio.
#'   The ratio of three is a heuristic, not a statistical significance test.
#'   The mean-competence threshold is not applied to the informal model, whose
#'   loadings are not probabilities of knowing an answer.
#' @references Romney, A. K., Weller, S. C., and Batchelder, W. H. (1986).
#'   Culture as consensus: A theory of culture and informant accuracy.
#'   American Anthropologist, 88(2), 313--338. \doi{10.1525/aa.1986.88.2.02a00020}.
#'   Romney, A. K., Batchelder, W. H., and Weller, S. C. (1987). Recent
#'   applications of cultural consensus theory. American Behavioral Scientist,
#'   31(2), 163--177. \doi{10.1177/000276487031002003}.
#'   Weller, S. C. (2007). Cultural consensus theory: Applications and frequently
#'   asked questions. Field Methods, 19(4), 339--368. \doi{10.1177/1525822X07303502}.
#' @examples
#' x <- simulate_consensus_data(24, 60, n_answers = 4, competence = 0.6, seed = 7)
#' fit <- consensus(x$responses, answer_levels = 1:4)
#' fit$mean_competence
#' head(fit$answer_key$key)
#'
#' @return An object of class `romney_consensus` containing:
#'   \itemize{
#'     \item \code{agreement}: respondent-by-respondent agreement matrix.
#'     \item \code{loadings}, \code{competence}: signed loadings for returned factors.
#'     \item \code{factor_ss_loadings}, \code{eigenvalues}: factor sums of squares.
#'     \item \code{raw_eigenvalues}: eigenvalues of the input agreement matrix.
#'     \item \code{ratio_eigen_1_2}, \code{mean_competence}, \code{criteria}:
#'       descriptive diagnostics, not significance tests.
#'     \item \code{answer_key}: model-specific key and item statuses, or NULL
#'       when not requested or invalid under the selected competence policy.
#'     \item \code{answer_key_weights}: weights actually used for that key.
#'     \item \code{diagnostics}: extraction warnings, communalities, residuals,
#'       overlap counts, factor-library version and answer-key status.
#'   }
#' @export
consensus <- function(
  data,
  cultures = 1,
  method = c("formal", "informal", "covariance"),
  prior = 0.5,
  return_answer_key = TRUE,
  n_answers = NULL,
  answer_levels = NULL,
  competence_policy = c("strict", "truncate")
) {
  data <- .as_matrix(data, min_respondents = 3L, min_questions = 2L)
  method <- match.arg(method)
  competence_policy <- match.arg(competence_policy)
  cultures <- .check_integer(cultures, "cultures", maximum = nrow(data) - 1L)
  if (!is.logical(return_answer_key) || length(return_answer_key) != 1L || is.na(return_answer_key)) {
    stop("`return_answer_key` must be TRUE or FALSE.", call. = FALSE)
  }
  if (method == "informal" && (!is.null(answer_levels) || !is.null(n_answers))) {
    stop("`answer_levels` and `n_answers` apply only to categorical models.", call. = FALSE)
  }
  if (method != "informal") {
    levels <- .check_levels(data, answer_levels, minimum = if (is.null(n_answers)) 2L else 1L)
    if (!is.null(n_answers)) {
      n_answers <- .check_integer(n_answers, "n_answers", minimum = 2L)
      if (n_answers < length(levels) ||
          (!is.null(answer_levels) && n_answers != length(levels))) {
        stop("`n_answers` must agree with the allowable response categories.", call. = FALSE)
      }
      if (return_answer_key && n_answers != length(levels)) {
        stop("Specify `answer_levels` to estimate a key when some options were unobserved.", call. = FALSE)
      }
    } else {
      n_answers <- length(levels)
    }
    if (method == "covariance" && (length(levels) != 2L || n_answers != 2L)) {
      stop("The covariance model requires exactly two response categories.", call. = FALSE)
    }
  }

  agreement <- switch(
    method,
    formal = agreement_formal(data, n_answers = n_answers),
    informal = agreement_informal(data),
    covariance = agreement_covariance(data, prior = prior, answer_levels = levels)
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

  competence <- loadings

  eigenvalues <- factor_fit$values
  ratio <- if (length(eigenvalues) >= 2 && eigenvalues[2] > 0) {
    eigenvalues[1] / eigenvalues[2]
  } else {
    if (eigenvalues[1] > 0) Inf else NA_real_
  }

  mean_comp <- colMeans(competence, na.rm = TRUE)
  negative_first <- sum(loadings[, 1] < 0, na.rm = TRUE)
  criteria <- c(
    eigen_ratio_gt_3 = ratio > 3,
    mean_competence_gt_0_5 = if (method == "informal") NA else unname(mean_comp[1] > 0.5),
    no_negative_first_factor = negative_first == 0
  )

  answer <- NULL
  answer_weights <- competence[, 1]
  outside <- answer_weights < 0 | answer_weights > 1
  if (any(outside)) {
    warning("First-factor loadings outside [0, 1] were retained; inspect model adequacy.", call. = FALSE)
  }
  answer_status <- "not_requested"
  if (return_answer_key) {
    if (method != "informal" && any(outside) && competence_policy == "strict") {
      answer_status <- "invalid_competence"
      warning("Answer key not estimated: first-factor competence is outside [0, 1].", call. = FALSE)
    } else {
      if (method != "informal" && any(outside)) {
        answer_weights <- pmin(1, pmax(0, answer_weights))
        warning("Only answer-key weights were explicitly truncated to [0, 1].", call. = FALSE)
      }
      answer <- switch(method,
        formal = answerkey_formal(data, answer_weights, answer_levels = levels),
        covariance = answerkey_covariance(data, answer_weights, answer_levels = levels),
        informal = answerkey_informal(data, answer_weights)
      )
      answer_status <- "estimated"
    }
  }

  out <- list(
    method = method,
    prior = if (method == "covariance") prior else NULL,
    cultures = cultures,
    agreement = agreement,
    eigenvalues = eigenvalues,
    factor_ss_loadings = eigenvalues,
    raw_eigenvalues = factor_fit$raw_eigenvalues,
    factor_method = factor_fit$method,
    loadings = loadings,
    competence = competence,
    ratio_eigen_1_2 = ratio,
    mean_competence = mean_comp,
    negative_competence_first_factor = negative_first,
    criteria = criteria,
    criteria_met = sum(criteria, na.rm = TRUE),
    answer_key = answer,
    answer_key_weights = if (is.null(answer)) NULL else answer_weights,
    n_answers = if (method == "informal") NULL else n_answers,
    answer_levels = if (method == "informal") NULL else levels,
    diagnostics = list(
      extracted_factors = factor_fit$extraction_factors,
      positive_semidefinite = factor_fit$positive_semidefinite,
      factor_warnings = factor_fit$warnings,
      communalities = factor_fit$communalities,
      residuals = factor_fit$residuals,
      pairwise_items = tcrossprod(!is.na(data)),
      out_of_range_first_factor = sum(outside),
      answer_key_status = answer_status,
      competence_policy = competence_policy,
      psych_version = as.character(utils::packageVersion("psych"))
    )
  )

  class(out) <- "romney_consensus"
  out
}

#' @export
print.romney_consensus <- function(x, ...) {
  cat("Consensus analysis (", x$method, ")\n", sep = "")
  cat("  first factor SS: ", round(x$eigenvalues[1], 3), "\n", sep = "")
  if (length(x$eigenvalues) >= 2) {
    cat("  second factor SS:", round(x$eigenvalues[2], 3), "\n")
    cat("  ratio 1/2:       ", round(x$ratio_eigen_1_2, 3), "\n", sep = "")
  }
  cat("  mean competence: ", round(x$mean_competence[1], 3), "\n", sep = "")
  cat("  negatives first: ", x$negative_competence_first_factor, "\n", sep = "")
  cat("  extraction:     ", x$factor_method, "\n", sep = "")
  cat("  answer key:     ", x$diagnostics$answer_key_status, "\n", sep = "")
  invisible(x)
}

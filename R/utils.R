.as_matrix <- function(data, min_respondents = 1L, min_questions = 1L) {
  if (is.data.frame(data)) {
    data <- as.matrix(data)
  }
  if (!is.matrix(data)) {
    stop("`data` must be a matrix or data.frame.", call. = FALSE)
  }
  if (!(is.numeric(data) || is.character(data) || is.logical(data)) || is.complex(data)) {
    stop("`data` must contain numeric, character, or logical responses.", call. = FALSE)
  }
  if (nrow(data) < min_respondents || ncol(data) < min_questions) {
    stop(sprintf("`data` needs at least %d respondent(s) and %d item(s).",
                 min_respondents, min_questions), call. = FALSE)
  }
  if (is.numeric(data) && any(!is.na(data) & !is.finite(data))) {
    stop("Responses must be finite or NA.", call. = FALSE)
  }
  data
}

.check_integer <- function(x, name, minimum = 1L, maximum = .Machine$integer.max) {
  if (!is.numeric(x) || is.complex(x) || length(x) != 1L || !is.finite(x) ||
      x != floor(x) || x < minimum || x > maximum) {
    stop(sprintf("`%s` must be a finite integer between %s and %s.",
                 name, minimum, maximum), call. = FALSE)
  }
  as.integer(x)
}

.check_competence <- function(competence, n, probability = TRUE) {
  if (!is.numeric(competence) || is.complex(competence) ||
      length(competence) != n || any(!is.finite(competence))) {
    stop("`competence` must contain one finite numeric value per respondent.", call. = FALSE)
  }
  if (probability && any(competence < 0 | competence > 1)) {
    stop("All competence values must be in [0, 1].", call. = FALSE)
  }
  unname(competence)
}

.check_levels <- function(data, answer_levels = NULL, minimum = 2L) {
  if (is.null(answer_levels)) answer_levels <- .answer_levels(data)
  if (!is.atomic(answer_levels) || !is.null(dim(answer_levels)) ||
      is.factor(answer_levels) || is.complex(answer_levels) ||
      !(is.numeric(answer_levels) || is.character(answer_levels) || is.logical(answer_levels)) ||
      length(answer_levels) < minimum || anyNA(answer_levels) || anyDuplicated(answer_levels) ||
      (is.numeric(answer_levels) && any(!is.finite(answer_levels)))) {
    stop("`answer_levels` must be a vector of distinct, non-missing allowable responses.", call. = FALSE)
  }
  if (any(!is.na(data) & !(data %in% answer_levels))) {
    stop("Observed responses must all be included in `answer_levels`.", call. = FALSE)
  }
  answer_levels
}

.pairwise_counts <- function(data, minimum) {
  counts <- tcrossprod(!is.na(data))
  bad <- which(counts < minimum & lower.tri(counts, diag = TRUE), arr.ind = TRUE)
  if (nrow(bad)) {
    stop(sprintf("Respondents %d and %d have fewer than %d jointly observed items.",
                 bad[1, 1], bad[1, 2], minimum), call. = FALSE)
  }
  dimnames(counts) <- list(.respondent_names(data), .respondent_names(data))
  counts
}

.key_from_scores <- function(scores, levels, status) {
  key <- levels[rep(NA_integer_, ncol(scores))]
  for (j in seq_len(ncol(scores))) {
    if (status[j] != "estimated") next
    winners <- which(abs(scores[, j] - max(scores[, j])) <= 1e-12)
    if (length(winners) == 1L) key[j] <- levels[winners] else status[j] <- "tie"
  }
  names(key) <- colnames(scores)
  names(status) <- colnames(scores)
  list(key = key, status = status)
}

.categorical_votes <- function(data, competence, levels) {
  scores <- matrix(NA_real_, length(levels), ncol(data),
                   dimnames = list(as.character(levels), .question_names(data)))
  status <- rep("estimated", ncol(data))
  for (j in seq_len(ncol(data))) {
    keep <- !is.na(data[, j])
    total <- sum(competence[keep])
    if (!any(keep)) {
      status[j] <- "no_data"
    } else if (total <= 0) {
      status[j] <- "zero_weight"
    } else {
      scores[, j] <- vapply(levels, function(level) {
        sum(competence[keep & data[, j] == level]) / total
      }, numeric(1))
    }
  }
  selected <- .key_from_scores(scores, levels, status)
  list(key = selected$key, status = selected$status,
       weighted_proportions = scores, weighted_frequencies = nrow(data) * scores)
}

.respondent_names <- function(data) {
  rn <- rownames(data)
  if (is.null(rn)) {
    rn <- paste0("respondent_", seq_len(nrow(data)))
  }
  rn
}

.question_names <- function(data) {
  cn <- colnames(data)
  if (is.null(cn)) {
    cn <- paste0("question_", seq_len(ncol(data)))
  }
  cn
}

.answer_levels <- function(data) {
  vec <- as.vector(data)
  vec <- vec[!is.na(vec)]
  if (length(vec) == 0) {
    stop("`data` contains only missing values.", call. = FALSE)
  }
  sort(unique(vec))
}

.fit_consensus_factors <- function(agreement, cultures) {
  if (!is.matrix(agreement) || nrow(agreement) != ncol(agreement)) {
    stop("`agreement` must be a square matrix.", call. = FALSE)
  }
  if (!is.numeric(agreement) || any(!is.finite(agreement)) ||
      !isTRUE(all.equal(agreement, t(agreement), check.attributes = FALSE))) {
    stop("`agreement` must be finite, numeric, and symmetric.", call. = FALSE)
  }

  raw_eigenvalues <- eigen(agreement, symmetric = TRUE, only.values = TRUE)$values
  extraction_factors <- min(max(as.integer(cultures), 2L), max(1L, nrow(agreement) - 1L))
  fit_warnings <- character()
  fa_fit <- tryCatch(
    withCallingHandlers(psych::fa(
      r = agreement,
      nfactors = extraction_factors,
      residuals = TRUE,
      rotate = "none",
      scores = "none",
      impute = "mean",
      fm = "minres",
      warnings = TRUE,
      min.err = 0.001,
      max.iter = 50
    ), warning = function(w) {
      fit_warnings <<- c(fit_warnings, conditionMessage(w))
    }),
    error = function(e) stop(paste("Minimum-residual factor extraction failed:",
                                   conditionMessage(e)), call. = FALSE)
  )

  values <- fa_fit$Vaccounted["SS loadings", ]
  values <- as.numeric(values)
  loadings <- as.matrix(unclass(fa_fit$loadings))
  if (any(!is.finite(values)) || any(!is.finite(loadings))) {
    stop("Minimum-residual extraction produced non-finite estimates.", call. = FALSE)
  }

  list(
    values = values,
    raw_eigenvalues = raw_eigenvalues,
    loadings = loadings,
    extraction_factors = extraction_factors,
    method = "minres",
    warnings = unique(fit_warnings),
    communalities = fa_fit$communality,
    residuals = fa_fit$residual,
    positive_semidefinite = min(raw_eigenvalues) >= -1e-8
  )
}

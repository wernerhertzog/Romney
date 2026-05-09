.as_matrix <- function(data) {
  if (is.data.frame(data)) {
    data <- as.matrix(data)
  }
  if (!is.matrix(data)) {
    stop("`data` must be a matrix or data.frame.", call. = FALSE)
  }
  data
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

  raw_eigenvalues <- eigen(agreement, symmetric = TRUE, only.values = TRUE)$values
  extraction_factors <- min(max(as.integer(cultures), 2L), max(1L, nrow(agreement) - 1L))

  fa_fit <- tryCatch(
    psych::fa(
      r = agreement,
      nfactors = extraction_factors,
      residuals = TRUE,
      rotate = "none",
      scores = "regression",
      impute = "mean",
      fm = "minres",
      warnings = FALSE
    ),
    error = function(e) NULL
  )

  if (is.null(fa_fit)) {
    eig <- eigen(agreement, symmetric = TRUE)
    loadings <- eig$vectors[, seq_len(cultures), drop = FALSE] %*%
      diag(sqrt(pmax(eig$values[seq_len(cultures)], 0)), nrow = cultures)
    return(list(
      values = eig$values,
      raw_eigenvalues = raw_eigenvalues,
      loadings = loadings,
      extraction_factors = cultures,
      method = "eigen"
    ))
  }

  values <- fa_fit$Vaccounted["SS loadings", ]
  values <- as.numeric(values)
  loadings <- as.matrix(unclass(fa_fit$loadings))

  list(
    values = values,
    raw_eigenvalues = raw_eigenvalues,
    loadings = loadings,
    extraction_factors = extraction_factors,
    method = "minres"
  )
}

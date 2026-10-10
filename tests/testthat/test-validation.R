test_that("invalid matrices and parameters are rejected before extraction", {
  x <- rbind(c(1, 2, 1), c(1, 1, 2), c(2, 1, 2))
  expect_error(consensus(x[1, , drop = FALSE]), "at least 3")
  expect_error(consensus(x[, 1, drop = FALSE]), "at least 3")
  expect_error(consensus(matrix(numeric(), 0, 0)), "at least")
  expect_error(consensus(replace(x, 1, Inf)), "finite or NA")
  for (bad in list(1.9, NA_real_, Inf, 0, c(1, 2))) {
    expect_error(consensus(x, cultures = bad), "finite integer")
  }
  expect_error(consensus(x, cultures = 3), "finite integer")
  expect_error(consensus(x, return_answer_key = NA), "TRUE or FALSE")
  expect_error(consensus(x, n_answers = 4), "Specify `answer_levels`")
  expect_error(consensus(x, answer_levels = 1:4, n_answers = 3), "agree")
  expect_error(consensus(x, method = "informal", n_answers = 4), "categorical")
})

test_that("missingness and undefined correlations produce informative errors", {
  no_overlap <- rbind(c(1, 2, NA, NA), c(NA, NA, 1, 2))
  expect_error(agreement_formal(no_overlap), "jointly observed")
  expect_error(agreement_covariance(no_overlap), "jointly observed")
  expect_error(agreement_informal(no_overlap), "jointly observed")
  expect_error(agreement_informal(rbind(rep(1, 4), 1:4)), "constant")
  overlap_constant <- rbind(c(1, 1, 2, NA), c(2, 2, NA, 3))
  expect_error(agreement_informal(overlap_constant), "jointly observed items")
  expect_error(agreement_formal(rbind(c(NA, NA), c(1, 2))), "jointly observed")
  expect_error(agreement_covariance(rbind(c(0, 1), c(1, 0)), prior = NA_real_), "between")
})

test_that("declared but unobserved categories control chance correction", {
  x <- rbind(c(1, 2, 1, 2), c(2, 1, 2, 1))
  expect_equal(unname(agreement_formal(x, 4)[1, 2]), -1 / 3)
  expect_equal(unname(agreement_formal(x, 2)[1, 2]), -1)
  expect_error(agreement_formal(x, n_answers = 1.9), "finite integer")
  expect_error(agreement_formal(rbind(1:3, 1:3), n_answers = 2), "smaller")
  binary <- agreement_covariance(matrix(0, 2, 3), answer_levels = 0:1)
  expect_equal(unname(binary[1, 2]), 0)
})

test_that("competence and diagnostics retain signed loadings", {
  mock <- function(agreement, cultures) list(
    loadings = matrix(c(0.8, 0.7, -0.2), ncol = 1), values = c(1.2, 0.1),
    raw_eigenvalues = c(2, 0.6, 0.4), method = "minres", extraction_factors = 2L,
    warnings = character(), communalities = c(0.64, 0.49, 0.04),
    residuals = matrix(0, 3, 3), positive_semidefinite = TRUE
  )
  local_mocked_bindings(.fit_consensus_factors = mock)
  x <- rbind(c(1, 2, 1), c(1, 1, 2), c(2, 1, 2))
  expect_warning(fit <- consensus(x, return_answer_key = FALSE), "outside")
  expect_equal(unname(fit$competence[, 1]), c(0.8, 0.7, -0.2))
  expect_equal(unname(fit$mean_competence), 1.3 / 3)
  expect_false(fit$criteria["mean_competence_gt_0_5"])
  expect_equal(fit$negative_competence_first_factor, 1)
  strict <- suppressWarnings(consensus(x))
  expect_null(strict$answer_key)
  expect_equal(strict$diagnostics$answer_key_status, "invalid_competence")
  clipped <- suppressWarnings(consensus(x, competence_policy = "truncate"))
  expect_equal(unname(clipped$answer_key_weights), c(0.8, 0.7, 0))
  expect_identical(clipped$competence, strict$competence)
  informal <- suppressWarnings(consensus(x, method = "informal"))
  expect_true(is.na(informal$criteria["mean_competence_gt_0_5"]))
  expect_equal(unname(informal$answer_key_weights), c(0.8, 0.7, -0.2))
})

test_that("factor-extraction errors do not silently substitute eigen decomposition", {
  local_mocked_bindings(fa = function(...) stop("forced extraction failure"), .package = "psych")
  x <- rbind(c(1, 2, 1), c(1, 1, 2), c(2, 1, 2))
  expect_error(consensus(x), "Minimum-residual factor extraction failed: forced extraction failure")
})

test_that("factor helper rejects non-finite and nonsymmetric matrices", {
  expect_error(.fit_consensus_factors(matrix(NA_real_, 3, 3), 1), "finite, numeric")
  bad <- diag(3); bad[1, 2] <- 0.1
  expect_error(.fit_consensus_factors(bad, 1), "symmetric")
})

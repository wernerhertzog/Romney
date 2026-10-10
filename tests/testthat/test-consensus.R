extdata_path <- function(...) {
  installed <- system.file("extdata", ..., package = "Romney")
  if (nzchar(installed)) {
    return(installed)
  }
  testthat::test_path("..", "..", "inst", "extdata", ...)
}

read_extdata_csv <- function(name) {
  as.matrix(read.csv(extdata_path(name), row.names = 1, check.names = FALSE))
}

test_that("consensus returns expected structure", {
  sim <- simulate_consensus_data(12, 20, n_answers = 4, competence = 0.75, seed = 1)
  fit <- consensus(sim$responses, method = "formal")

  expect_s3_class(fit, "romney_consensus")
  expect_equal(dim(fit$agreement), c(12, 12))
  expect_length(fit$raw_eigenvalues, 12)
  expect_true(is.list(fit$answer_key))
})

test_that("binary covariance synthetic data matches UCINET closely", {
  x <- read_extdata_csv("synthetic_yesno_36x103.csv")
  fit <- consensus(x, method = "covariance", prior = 0.5)

  expect_equal(fit$factor_method, "minres")
  expect_equal(unname(round(fit$eigenvalues[1], 3)), 8.944, tolerance = 0.05)
  expect_equal(unname(round(fit$eigenvalues[2], 3)), 1.126, tolerance = 0.05)
  expect_equal(unname(round(fit$ratio_eigen_1_2, 3)), 7.940, tolerance = 0.2)
  expect_equal(
    unname(round(fit$competence[1:5, 1], 3)),
    c(0.397, 0.712, 0.085, 0.237, 0.402),
    tolerance = 0.03
  )
})

test_that("multiple-choice synthetic data matches UCINET closely", {
  x <- read_extdata_csv("synthetic_multiple_choice_36x103_k4.csv")
  fit <- consensus(x, method = "formal")

  expect_equal(fit$factor_method, "minres")
  expect_equal(unname(round(fit$eigenvalues[1], 3)), 12.671, tolerance = 0.05)
  expect_equal(unname(round(fit$eigenvalues[2], 3)), 0.661, tolerance = 0.05)
  expect_equal(unname(round(fit$ratio_eigen_1_2, 3)), 19.160, tolerance = 1)
  expect_equal(unname(fit$answer_key$key[1:10]), c(1, 1, 2, 4, 3, 4, 1, 3, 2, 2))
  expect_equal(
    unname(round(fit$competence[1:5, 1], 3)),
    c(0.479, 0.636, 0.908, 0.719, 0.524),
    tolerance = 0.03
  )
})

test_that("ordinal synthetic data matches UCINET closely", {
  x <- read_extdata_csv("synthetic_ordinal_36x103_1to5.csv")
  fit <- consensus(x, method = "informal")

  expect_equal(fit$factor_method, "minres")
  expect_equal(unname(round(fit$eigenvalues[1], 3)), 27.383, tolerance = 0.05)
  expect_equal(unname(round(fit$eigenvalues[2], 3)), 0.443, tolerance = 0.05)
  expect_equal(unname(round(fit$ratio_eigen_1_2, 3)), 61.871, tolerance = 3)
  expect_equal(
    unname(round(fit$competence[1:5, 1], 3)),
    c(0.860, 0.858, 0.992, 0.730, 0.900),
    tolerance = 0.03
  )
})

test_that("complete UCINET tables are compared for each reference dataset", {
  for (i in seq_len(nrow(ucinet_cases))) {
    case <- ucinet_cases[i, ]
    x <- read_extdata_csv(case$csv)
    reference <- ucinet_reference(extdata_path("ucinet_results", case$log), nrow(x), ncol(x))
    fit <- consensus(x, method = case$method)
    expect_equal(fit$factor_method, "minres")
    expect_equal(fit$diagnostics$extracted_factors, 2L)
    expect_lt(max(abs(fit$agreement - reference$agreement)), 0.00050001)
    expect_lt(max(abs(fit$competence[, 1] - reference$competence)), 0.01)
    expect_lt(abs(fit$factor_ss_loadings[1] - reference$factor_ss[1]), 0.025)
    expect_lt(abs(fit$factor_ss_loadings[2] - reference$factor_ss[2]), 0.01)
    expect_lt(abs(fit$ratio_eigen_1_2 - reference$ratio), if (case$method == "informal") 1.5 else 0.1)
    expect_equal(fit$negative_competence_first_factor, reference$negatives)
    expect_identical(fit$factor_ss_loadings, fit$eigenvalues)
    expect_length(fit$answer_key$key, ncol(x))
    expect_true(all(fit$answer_key$status == "estimated"))
    if (case$method == "informal") {
      expect_lt(max(abs(fit$answer_key$key - reference$key)), 0.001)
      expect_null(fit$answer_key$probabilities)
    } else {
      expect_equal(unname(fit$answer_key$key), reference$key)
      freq <- reference$frequencies
      observed <- mapply(function(item, response) sum(x[, item] == response, na.rm = TRUE), freq$item, freq$response)
      weighted <- mapply(function(item, response) {
        fit$answer_key$weighted_frequencies[as.character(response), item]
      }, freq$item, freq$response)
      expect_equal(unname(observed), freq$count)
      expect_lt(max(abs(weighted - freq$weighted)), 0.1)
      if (case$method == "formal") {
        expect_equal(unname(colSums(fit$answer_key$probabilities)), rep(1, ncol(x)))
      } else {
        expect_null(fit$answer_key$probabilities)
      }
    }
  }
})

test_that("all declared options reach both formal agreement and the answer key", {
  x <- read_extdata_csv("synthetic_multiple_choice_36x103_k4.csv")
  fit <- consensus(x, answer_levels = 1:5)
  expect_equal(fit$n_answers, 5L)
  expect_equal(fit$agreement, agreement_formal(x, n_answers = 5))
  expect_equal(fit$answer_key$levels, 1:5)
  expect_equal(nrow(fit$answer_key$probabilities), 5L)
})

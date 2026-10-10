test_that("formal answer key recovers consensus answers", {
  x <- rbind(
    c(1, 2, 1, 2),
    c(1, 2, 1, 2),
    c(1, 2, 2, 2),
    c(2, 1, 1, 2)
  )
  comp <- c(0.9, 0.9, 0.7, 0.2)

  key <- answerkey_formal(x, competence = comp)

  expect_equal(unname(key$key), c(1, 2, 1, 2))
  expect_equal(dim(key$probabilities), c(2, 4))
})

test_that("formal posterior probabilities use each particular incorrect option", {
  x <- matrix("A", 1, 1)
  none <- answerkey_formal(x, 0, answer_levels = LETTERS[1:4])
  expect_equal(unname(none$probabilities[, 1]), rep(0.25, 4))
  expect_true(is.na(none$key[1]))
  expect_equal(unname(none$status), "tie")
  skilled <- answerkey_formal(x, 0.8, answer_levels = LETTERS[1:4])
  expect_equal(unname(skilled$probabilities[, 1]), c(0.85, 0.05, 0.05, 0.05))
})

test_that("posterior probabilities agree with an independent direct calculation", {
  x <- matrix(c("A", "B", "A"), ncol = 1)
  competence <- c(0.8, 0.4, 0.2)
  prior <- c(0.1, 0.2, 0.3, 0.4)
  likelihood <- vapply(LETTERS[1:4], function(candidate) {
    prod(vapply(seq_len(3), function(i) {
      if (x[i, 1] == candidate) competence[i] + (1 - competence[i]) / 4 else (1 - competence[i]) / 4
    }, numeric(1)))
  }, numeric(1))
  expected <- prior * likelihood / sum(prior * likelihood)
  fit <- answerkey_formal(x, competence, prior, LETTERS[1:4])
  expect_equal(unname(fit$probabilities[, 1]), unname(expected))
  expect_equal(sum(fit$probabilities), 1)
})

test_that("formal posteriors remain stable when raw likelihood products underflow", {
  fit <- answerkey_formal(matrix(rep(1, 2000), ncol = 1), rep(0.2, 2000), answer_levels = 1:4)
  expect_true(all(is.finite(fit$probabilities)))
  expect_equal(sum(fit$probabilities), 1)
  expect_equal(unname(fit$key), 1)
})

test_that("impossible observations, ties and unobserved items are not arbitrary keys", {
  x <- matrix(c(1, 2), ncol = 1)
  expect_warning(impossible <- answerkey_formal(x, c(1, 1)), "zero likelihood")
  expect_true(all(is.na(impossible$probabilities)))
  expect_true(all(is.na(impossible$key)))
  expect_equal(unname(impossible$status), "impossible")
  missing <- answerkey_formal(matrix(NA_real_, 2, 1), c(0.5, 0.5), prior = c(0.8, 0.2), answer_levels = 1:2)
  expect_true(is.na(missing$key[1]))
  expect_equal(unname(missing$probabilities[, 1]), c(0.8, 0.2))
  expect_equal(unname(missing$status), "no_data")
  tied <- answerkey_formal(x, c(0.5, 0.5))
  expect_equal(unname(tied$status), "tie")
  expect_true(is.na(tied$key[1]))
})

test_that("declared categories and priors are validated", {
  x <- matrix(c("A", "B", "X"), ncol = 1)
  expect_error(answerkey_formal(x, rep(0.5, 3), answer_levels = c("A", "B")), "included")
  for (levels in list(c("A", "A"), c("A", NA), matrix(c("A", "B")), factor(c("A", "B")))) {
    expect_error(answerkey_formal(x, rep(0.5, 3), answer_levels = levels), "distinct")
  }
  y <- matrix(c(1, 2), ncol = 1)
  for (prior in list(c(0, 0), c(-1, 2), c(NA, 1), matrix(c("a", "b"), 2, 1))) {
    expect_error(answerkey_formal(y, c(0.5, 0.5), prior = prior))
  }
  fit <- answerkey_formal(y, c(0, 0), prior = c(1e308, 1e308))
  expect_equal(unname(fit$probabilities[, 1]), c(0.5, 0.5))
  zero <- answerkey_formal(matrix(1, 1, 1), 0.5, prior = c(0, 1), answer_levels = 1:2)
  expect_equal(unname(zero$probabilities[, 1]), c(0, 1))
})

test_that("binary votes are normalized over observed responses and retain ambiguity", {
  x <- cbind(c(0, 1, 1), c(0, 1, NA), c(NA, NA, NA))
  fit <- answerkey_covariance(x, c(0.2, 0.8, 0.7))
  expect_equal(unname(fit$key), c(1, 1, NA_real_))
  expect_equal(unname(fit$weighted_proportions[, 1]), c(0.2, 1.5) / 1.7)
  expect_equal(unname(fit$weighted_proportions[, 2]), c(0.2, 0.8))
  expect_equal(unname(colSums(fit$weighted_frequencies)[1:2]), c(3, 3))
  tie <- answerkey_covariance(matrix(c(0, 1), ncol = 1), c(0.5, 0.5))
  expect_true(is.na(tie$key[1]))
  expect_equal(unname(tie$status), "tie")
  zero <- answerkey_covariance(matrix(c(0, 1), ncol = 1), c(0, 0))
  expect_equal(unname(zero$status), "zero_weight")
  expect_true(all(is.na(zero$weighted_proportions)))
})

test_that("informal keys are signed, original-scale weighted means", {
  x <- rbind(c(1, 4, NA), c(2, NA, NA), c(3, 5, NA))
  fit <- answerkey_informal(x, c(0.8, 0.4, 0.2))
  expect_equal(unname(fit$key), c(2.2 / 1.4, 4.2, NA_real_))
  expect_equal(unname(fit$status), c("estimated", "estimated", "no_data"))
  expect_equal(unname(fit$weight_sum), c(1.4, 1, 0))
  signed <- answerkey_informal(matrix(c(1, 3), ncol = 1), c(0.8, -0.2))
  expect_equal(unname(signed$key), 1 / 3)
  invalid <- answerkey_informal(matrix(c(1, 3), ncol = 1), c(0.2, -0.2))
  expect_true(is.na(invalid$key[1]))
  expect_error(answerkey_informal(matrix(c("A", "B"), ncol = 1), c(0.2, 0.8)), "numeric")
})

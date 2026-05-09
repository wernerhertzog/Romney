test_that("formal agreement applies guessing correction", {
  x <- rbind(
    c(1, 1, 2),
    c(1, 2, 2),
    c(2, 2, 2)
  )

  out <- agreement_formal(x, n_answers = 2)

  expect_equal(unname(diag(out)), c(1, 1, 1))
  expect_equal(unname(out[1, 2]), 1 / 3)
  expect_equal(unname(out[1, 3]), -1 / 3)
  expect_equal(out, t(out))
})

test_that("informal agreement uses pairwise correlations", {
  x <- rbind(
    c(1, 2, 3, 4),
    c(2, 4, 6, 8),
    c(4, 3, 2, 1)
  )

  out <- agreement_informal(x)

  expect_equal(unname(out[1, 2]), 1)
  expect_equal(round(unname(out[1, 3]), 6), -1)
  expect_equal(unname(diag(out)), c(1, 1, 1))
})

test_that("covariance agreement handles binary data", {
  x <- rbind(
    c(0, 1, 1, 0, 1),
    c(0, 1, 0, 0, 1),
    c(1, 0, 0, 1, 0)
  )

  out <- agreement_covariance(x, prior = 0.5)

  expect_equal(dim(out), c(3, 3))
  expect_true(all(diag(out) == 1))
  expect_equal(out, t(out))
})

test_that("simulation implements uniform guessing, including the correct option", {
  for (m in 2:4) {
    for (c in c(0, 0.4, 1)) {
      s <- simulate_consensus_data(30, 1200, m, c, seed = 421)
      truth <- matrix(s$key, nrow = 30, ncol = 1200, byrow = TRUE)
      expect_lt(abs(mean(s$responses == truth) - (c + (1 - c) / m)), 0.015)
      expect_true(all(s$responses %in% seq_len(m)))
      if (c == 0) {
        for (k in seq_len(m)) {
          keep <- s$key == k
          expect_lt(abs(mean(s$responses[, keep] == k) - 1 / m), 0.025)
        }
      }
    }
  }
})

test_that("simulated pairwise agreement estimates the competence product", {
  s <- simulate_consensus_data(3, 8000, 4, c(0.3, 0.6, 0.9), seed = 23)
  agreement <- agreement_formal(s$responses, n_answers = 4)
  target <- outer(s$competence, s$competence)
  expect_lt(max(abs(agreement[lower.tri(agreement)] - target[lower.tri(target)])), 0.03)
})

test_that("an explicit seed is reproducible and preserves the caller's RNG", {
  set.seed(129)
  before <- .Random.seed
  a <- simulate_consensus_data(3, 12, seed = 81)
  expect_identical(.Random.seed, before)
  expect_identical(a, simulate_consensus_data(3, 12, seed = 81))
  simulate_consensus_data(3, 12)
  expect_false(identical(.Random.seed, before))
})

test_that("simulation restores an initially absent random seed", {
  old <- .Random.seed
  on.exit(assign(".Random.seed", old, envir = .GlobalEnv), add = TRUE)
  rm(".Random.seed", envir = .GlobalEnv)
  simulate_consensus_data(3, 12, seed = 81)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
})

test_that("simulation rejects invalid dimensions, competence and seeds", {
  for (bad in list(NA_real_, Inf, 2.5, c(2, 3), 1 + 1i)) {
    expect_error(simulate_consensus_data(bad, 20), "finite integer")
    expect_error(simulate_consensus_data(3, bad), "finite integer")
    expect_error(simulate_consensus_data(3, 20, n_answers = bad), "finite integer")
  }
  expect_error(simulate_consensus_data(3, 20, competence = c(0.2, 0.3)), "one finite")
  expect_error(simulate_consensus_data(3, 20, competence = NA_real_), "finite")
  expect_error(simulate_consensus_data(3, 20, competence = 1.1), "\\[0, 1\\]")
  expect_error(simulate_consensus_data(3, 20, seed = -1), "finite integer")
})

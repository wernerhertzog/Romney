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

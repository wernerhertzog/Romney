#' Simulate formal consensus data
#'
#' @param n_respondents Number of respondents.
#' @param n_questions Number of questions/items.
#' @param n_answers Number of possible answers per item.
#' @param competence Scalar or vector of respondent competences.
#' @param seed Optional random seed.
#'
#' @return A list with `responses`, `key`, and `competence`.
#' @export
simulate_consensus_data <- function(
  n_respondents,
  n_questions,
  n_answers = 2,
  competence = 0.7,
  seed = NULL
) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (!is.numeric(n_respondents) || n_respondents < 2) {
    stop("`n_respondents` must be >= 2.", call. = FALSE)
  }
  if (!is.numeric(n_questions) || n_questions < 1) {
    stop("`n_questions` must be >= 1.", call. = FALSE)
  }
  if (!is.numeric(n_answers) || n_answers < 2) {
    stop("`n_answers` must be >= 2.", call. = FALSE)
  }

  n_respondents <- as.integer(n_respondents)
  n_questions <- as.integer(n_questions)
  n_answers <- as.integer(n_answers)

  if (length(competence) == 1) {
    competence <- rep(competence, n_respondents)
  }
  if (!is.numeric(competence) || length(competence) != n_respondents) {
    stop("`competence` must be scalar or length n_respondents.", call. = FALSE)
  }
  if (any(!is.finite(competence)) || any(competence < 0) || any(competence > 1)) {
    stop("All competence values must be finite and in [0, 1].", call. = FALSE)
  }

  key <- sample.int(n_answers, size = n_questions, replace = TRUE)
  responses <- matrix(NA_integer_, nrow = n_respondents, ncol = n_questions)

  for (i in seq_len(n_respondents)) {
    for (j in seq_len(n_questions)) {
      if (stats::runif(1) <= competence[i]) {
        responses[i, j] <- key[j]
      } else {
        wrong <- setdiff(seq_len(n_answers), key[j])
        responses[i, j] <- sample(wrong, size = 1)
      }
    }
  }

  rownames(responses) <- paste0("respondent_", seq_len(n_respondents))
  colnames(responses) <- paste0("question_", seq_len(n_questions))

  list(responses = responses, key = key, competence = competence)
}

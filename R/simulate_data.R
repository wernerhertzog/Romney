#' Simulate formal consensus data
#'
#' @param n_respondents Number of respondents.
#' @param n_questions Number of questions/items.
#' @param n_answers Number of possible answers per item.
#' @param competence Scalar or vector of respondent competences.
#' @param seed Optional non-negative integer seed. With a seed, the caller's
#'   random-number state is restored on exit.
#'
#' @details Respondent \eqn{i} knows an answer with probability \eqn{c_i}.
#'   Otherwise the respondent guesses uniformly among all \eqn{m} options,
#'   including the correct one. Thus the probability of a correct response is
#'   \eqn{c_i + (1-c_i)/m}, not \eqn{c_i}. Responses are conditionally independent
#'   given the answer key and competences. All items have the same choices and
#'   there is no response bias or missingness.
#' @references Romney, A. K., Weller, S. C., and Batchelder, W. H. (1986).
#'   Culture as consensus: A theory of culture and informant accuracy.
#'   American Anthropologist, 88(2), 313--338. \doi{10.1525/aa.1986.88.2.02a00020}.
#' @examples
#' simulated <- simulate_consensus_data(12, 30, n_answers = 4, seed = 42)
#' dim(simulated$responses)
#' @return A list with `responses`, `key`, and `competence`.
#' @export
simulate_consensus_data <- function(
  n_respondents,
  n_questions,
  n_answers = 2,
  competence = 0.7,
  seed = NULL
) {
  n_respondents <- .check_integer(n_respondents, "n_respondents", minimum = 2L)
  n_questions <- .check_integer(n_questions, "n_questions")
  n_answers <- .check_integer(n_answers, "n_answers", minimum = 2L)

  if (length(competence) == 1) {
    competence <- rep(competence, n_respondents)
  }
  competence <- .check_competence(competence, n_respondents)
  if (!is.null(seed)) {
    seed <- .check_integer(seed, "seed", minimum = 0L)
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(seed)
  }

  key <- sample.int(n_answers, size = n_questions, replace = TRUE)
  responses <- matrix(NA_integer_, nrow = n_respondents, ncol = n_questions)

  for (i in seq_len(n_respondents)) {
    for (j in seq_len(n_questions)) {
      if (stats::runif(1) <= competence[i]) {
        responses[i, j] <- key[j]
      } else {
        responses[i, j] <- sample.int(n_answers, size = 1L)
      }
    }
  }

  rownames(responses) <- paste0("respondent_", seq_len(n_respondents))
  colnames(responses) <- paste0("question_", seq_len(n_questions))

  list(responses = responses, key = key, competence = competence)
}

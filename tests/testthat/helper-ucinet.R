read_ucinet_log <- function(path) {
  con <- file(path, "rb")
  bom <- readBin(con, "raw", 2L)
  close(con)
  encoding <- if (identical(bom, as.raw(c(255, 254)))) "UTF-16LE" else
    if (identical(bom, as.raw(c(254, 255)))) "UTF-16BE" else "UTF-8"
  con <- file(path, encoding = encoding)
  on.exit(close(con), add = TRUE)
  sub("^\ufeff", "", readLines(con, warn = FALSE))
}

ucinet_table <- function(lines, heading, nr, nc) {
  start <- grep(heading, lines, fixed = TRUE)[1L]
  if (is.na(start)) stop("Missing UCINET table: ", heading)
  ends <- grep("rows,", lines, fixed = TRUE)
  end <- ends[ends > start][1L]
  if (is.na(end)) stop("Unterminated UCINET table: ", heading)
  rows <- lines[seq.int(start + 1L, end - 1L)]
  separator <- grep("^\\s*-+(\\s+-+)*\\s*$", rows)[1L]
  if (is.na(separator)) stop("Missing UCINET table separator: ", heading)
  rows <- rows[seq.int(separator + 1L, length(rows))]
  rows <- rows[grepl("^\\s*[0-9]+\\s+\\S+\\s+-?[0-9]", rows)]
  tokens <- strsplit(trimws(rows), "\\s+")
  if (length(tokens) != nr || any(lengths(tokens) != nc + 2L)) {
    stop("Unexpected UCINET table dimensions: ", heading)
  }
  index <- vapply(tokens, function(x) as.integer(x[1L]), integer(1))
  if (!identical(index, seq_len(nr))) stop("Unexpected UCINET row order: ", heading)
  out <- do.call(rbind, lapply(tokens, function(x) as.numeric(x[-c(1L, 2L)])))
  if (any(!is.finite(out))) stop("Non-finite UCINET values: ", heading)
  out
}

ucinet_metric <- function(lines, label) {
  hit <- grep(label, lines, fixed = TRUE, value = TRUE)
  if (length(hit) != 1L) stop("Missing or ambiguous UCINET metric: ", label)
  as.numeric(sub(".*:\\s*", "", hit))
}

ucinet_reference <- function(path, n_respondents, n_questions) {
  lines <- read_ucinet_log(path)
  out <- list(
    agreement = ucinet_table(lines, "Agreement among respondents", n_respondents, n_respondents),
    competence = ucinet_table(lines, "Competence Scores:", n_respondents, 1L)[, 1L],
    key = ucinet_table(lines, "Answer Key", n_questions, 1L)[, 1L],
    factor_ss = c(ucinet_metric(lines, "Largest eigenvalue"),
                  ucinet_metric(lines, "2nd largest eigenvalue")),
    ratio = ucinet_metric(lines, "Ratio of largest to next"),
    negatives = ucinet_metric(lines, "No. of negative competencies"),
    version = trimws(grep("^UCINET ", lines, value = TRUE)),
    generated = trimws(grep("^Output generated:", lines, value = TRUE))
  )
  starts <- grep("^ITEM [0-9]+:", lines)
  if (length(starts)) {
    if (length(starts) != n_questions) stop("Missing UCINET item frequency tables.")
    out$frequencies <- do.call(rbind, lapply(seq_along(starts), function(j) {
      end <- if (j < length(starts)) starts[j + 1L] - 1L else grep("Answer Key", lines, fixed = TRUE)[1L] - 1L
      rows <- lines[seq.int(starts[j] + 1L, end)]
      rows <- rows[grepl("^\\s*-?[0-9]+\\s+[0-9]+\\s+[0-9]+\\.", rows)]
      values <- do.call(rbind, lapply(strsplit(trimws(rows), "\\s+"), as.numeric))
      if (is.null(values) || ncol(values) != 3L) stop("Invalid UCINET frequency table.")
      data.frame(item = j, response = values[, 1L], count = values[, 2L], weighted = values[, 3L])
    }))
  }
  out
}

ucinet_cases <- data.frame(
  dataset = c("binary", "multiple_choice", "ordinal"),
  method = c("covariance", "formal", "informal"),
  csv = c("synthetic_yesno_36x103.csv", "synthetic_multiple_choice_36x103_k4.csv",
          "synthetic_ordinal_36x103_1to5.csv"),
  log = c("binary_consensus.txt", "multiple_consensus.txt", "ordinal_consensus.txt"),
  stringsAsFactors = FALSE
)

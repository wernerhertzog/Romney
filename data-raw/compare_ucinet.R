run_ucinet_comparison <- function(package_dir = ".", output_dir = file.path(package_dir, "inst", "validation")) {
  package_dir <- normalizePath(package_dir, mustWork = TRUE)
  implementation <- new.env(parent = globalenv())
  for (path in list.files(file.path(package_dir, "R"), pattern = "\\.R$", full.names = TRUE)) {
    sys.source(path, envir = implementation)
  }
  sys.source(file.path(package_dir, "tests", "testthat", "helper-ucinet.R"), envir = implementation)
  cases <- implementation$ucinet_cases
  summary <- competence <- answers <- agreements <- frequencies <- list()
  for (i in seq_len(nrow(cases))) {
    case <- cases[i, ]
    csv <- file.path(package_dir, "inst", "extdata", case$csv)
    log <- file.path(package_dir, "inst", "extdata", "ucinet_results", case$log)
    x <- as.matrix(utils::read.csv(csv, row.names = 1, check.names = FALSE))
    ref <- implementation$ucinet_reference(log, nrow(x), ncol(x))
    fit <- implementation$consensus(x, method = case$method)
    key <- unname(fit$answer_key$key)
    summary[[i]] <- data.frame(
      dataset = case$dataset, model = case$method, respondents = nrow(x), items = ncol(x),
      missing_responses = sum(is.na(x)), ucinet_version = sub("^UCINET ([0-9.]+).*", "\\1", ref$version),
      ucinet_generated = sub("^Output generated: *", "", ref$generated),
      romney_version = read.dcf(file.path(package_dir, "DESCRIPTION"), fields = "Version")[1L],
      r_version = as.character(getRversion()), psych_version = as.character(utils::packageVersion("psych")),
      csv_md5 = unname(tools::md5sum(csv)), log_md5 = unname(tools::md5sum(log)),
      romney_factor_1 = fit$factor_ss_loadings[1], ucinet_factor_1 = ref$factor_ss[1],
      romney_factor_2 = fit$factor_ss_loadings[2], ucinet_factor_2 = ref$factor_ss[2],
      romney_ratio = fit$ratio_eigen_1_2, ucinet_ratio = ref$ratio,
      agreement_max_abs_difference = max(abs(fit$agreement - ref$agreement)),
      competence_max_abs_difference = max(abs(fit$competence[, 1] - ref$competence)),
      answer_max_abs_difference = max(abs(key - ref$key)),
      categorical_answers_equal = if (case$method == "informal") NA_integer_ else sum(key == ref$key),
      stringsAsFactors = FALSE
    )
    competence[[i]] <- data.frame(dataset = case$dataset, respondent = seq_len(nrow(x)),
                                romney = fit$competence[, 1], ucinet = ref$competence,
                                difference = fit$competence[, 1] - ref$competence)
    answers[[i]] <- data.frame(dataset = case$dataset, item = seq_len(ncol(x)),
                             romney = key, ucinet = ref$key, difference = key - ref$key,
                             status = unname(fit$answer_key$status))
    index <- expand.grid(respondent_1 = seq_len(nrow(x)), respondent_2 = seq_len(nrow(x)))
    agreements[[i]] <- data.frame(dataset = case$dataset, index, romney = as.vector(fit$agreement),
                                ucinet = as.vector(ref$agreement),
                                difference = as.vector(fit$agreement - ref$agreement))
    if (!is.null(ref$frequencies)) {
      freq <- ref$frequencies
      observed <- mapply(function(item, response) sum(x[, item] == response, na.rm = TRUE), freq$item, freq$response)
      weighted <- mapply(function(item, response) {
        fit$answer_key$weighted_frequencies[as.character(response), item]
      }, freq$item, freq$response)
      if (!all(observed == freq$count)) stop("UCINET frequencies do not match CSV responses.")
      frequencies[[i]] <- data.frame(dataset = case$dataset, item = freq$item, response = freq$response,
                                    observed_count = observed, ucinet_count = freq$count,
                                    romney_weighted = weighted, ucinet_weighted = freq$weighted,
                                    weighted_difference = weighted - freq$weighted)
      summary[[i]]$frequency_max_abs_difference <- max(abs(weighted - freq$weighted))
    } else {
      summary[[i]]$frequency_max_abs_difference <- NA_real_
    }
  }
  result <- do.call(rbind, summary)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  tables <- list(summary = result, competence = do.call(rbind, competence),
                 answers = do.call(rbind, answers), agreement = do.call(rbind, agreements),
                 frequencies = do.call(rbind, frequencies))
  for (name in names(tables)) {
    utils::write.csv(tables[[name]], file.path(output_dir, paste0("ucinet-", name, ".csv")), row.names = FALSE)
  }
  writeLines(trimws(capture.output(sessionInfo()), which = "right"),
             file.path(output_dir, "sessionInfo.txt"))
  print(result[, c("dataset", "romney_factor_1", "ucinet_factor_1", "romney_factor_2",
                   "ucinet_factor_2", "competence_max_abs_difference", "answer_max_abs_difference",
                   "categorical_answers_equal", "frequency_max_abs_difference")], row.names = FALSE)
  invisible(result)
}

if (sys.nframe() == 0L) run_ucinet_comparison()

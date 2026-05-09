write_ucinet_dl <- function(x, path, missing = -999) {
  if (is.data.frame(x)) {
    x <- as.matrix(x)
  }
  stopifnot(is.matrix(x))

  y <- x
  y[is.na(y)] <- missing

  con <- file(path, open = "wt")
  on.exit(close(con), add = TRUE)

  writeLines(sprintf("dl nr=%d nc=%d format=fullmatrix missing=%s", nrow(y), ncol(y), missing), con)
  writeLines("labels:", con)
  writeLines(paste(sprintf('"%s"', seq_len(nrow(y))), collapse = " "), con)
  writeLines("labels embedded", con)
  writeLines("data:", con)
  apply(y, 1, function(row) writeLines(paste(row, collapse = " "), con))
}

extdata_dir <- file.path("inst", "extdata")
ucinet_dir <- Sys.getenv("ROMNEY_UCINET_EXPORT_DIR", unset = path.expand("~/Documents/UCINET data"))
dir.create(ucinet_dir, recursive = TRUE, showWarnings = FALSE)

for (nm in c(
  "synthetic_yesno_36x103.csv",
  "synthetic_multiple_choice_36x103_k4.csv",
  "synthetic_ordinal_36x103_1to5.csv"
)) {
  x <- as.matrix(read.csv(file.path(extdata_dir, nm), row.names = 1, check.names = FALSE))
  out <- sub("\\.csv$", ".dl", nm)
  write_ucinet_dl(x, file.path(ucinet_dir, out))
}

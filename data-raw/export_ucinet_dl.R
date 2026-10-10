write_ucinet_dl <- function(x, path, missing = -999) {
  if (is.data.frame(x)) {
    x <- as.matrix(x)
  }
  if (!is.matrix(x) || !is.numeric(x) || !length(x) ||
      any(!is.na(x) & !is.finite(x))) {
    stop("DL export requires a non-empty numeric response matrix.", call. = FALSE)
  }
  if (!is.numeric(missing) || length(missing) != 1L || !is.finite(missing) ||
      any(x == missing, na.rm = TRUE)) {
    stop("The missing-value sentinel must be finite and absent from observed responses.", call. = FALSE)
  }
  if (file.exists(path)) stop("Refusing to overwrite existing DL file: ", path, call. = FALSE)

  y <- x
  y[is.na(y)] <- missing

  con <- file(path, open = "wt")
  on.exit(close(con), add = TRUE)

  writeLines(sprintf("dl nr=%d nc=%d format=fullmatrix missing=%s", nrow(y), ncol(y), missing), con)
  writeLines("data:", con)
  # Unlabelled fullmatrix rows avoid consuming the first response as a row label.
  apply(y, 1, function(row) writeLines(paste(row, collapse = " "), con))
  invisible(path)
}

export_reference_dl <- function(output_dir) {
  extdata_dir <- file.path("inst", "extdata")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (nm in c(
    "synthetic_yesno_36x103.csv",
    "synthetic_multiple_choice_36x103_k4.csv",
    "synthetic_ordinal_36x103_1to5.csv"
  )) {
    x <- as.matrix(read.csv(file.path(extdata_dir, nm), row.names = 1, check.names = FALSE))
    out <- sub("\\.csv$", ".dl", nm)
    write_ucinet_dl(x, file.path(output_dir, out))
  }
  invisible(output_dir)
}

if (sys.nframe() == 0L) {
  output_dir <- Sys.getenv("ROMNEY_UCINET_EXPORT_DIR")
  if (!nzchar(output_dir)) stop("Set ROMNEY_UCINET_EXPORT_DIR to a new export directory.", call. = FALSE)
  export_reference_dl(output_dir)
}

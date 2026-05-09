read_ucinet_dl <- function(path, row_prefix = "respondent", col_prefix = "item") {
  lines <- readLines(path, warn = FALSE)
  data_idx <- match("data:", trimws(lines))
  if (is.na(data_idx)) {
    stop("Could not find `data:` block in ", path, call. = FALSE)
  }

  header <- lines[1:data_idx]
  dims <- regmatches(header[1], gregexpr("[0-9]+", header[1]))[[1]]
  nr <- as.integer(dims[1])
  nc <- as.integer(dims[2])

  raw_data <- lines[(data_idx + 1):length(lines)]
  raw_data <- raw_data[nzchar(trimws(raw_data))]
  values <- scan(text = paste(raw_data, collapse = "\n"), what = numeric(), quiet = TRUE)
  values[values == -999] <- NA_real_

  if (length(values) != nr * nc) {
    stop("Parsed ", length(values), " values but expected ", nr * nc, ".", call. = FALSE)
  }

  out <- matrix(values, nrow = nr, ncol = nc, byrow = TRUE)
  rownames(out) <- paste0(row_prefix, "_", seq_len(nr))
  colnames(out) <- paste0(col_prefix, "_", seq_len(nc))
  out
}

write_dataset <- function(src, dest) {
  x <- read_ucinet_dl(src)
  write.csv(x, dest, row.names = TRUE)
  invisible(dest)
}

ucinet_dir <- Sys.getenv("ROMNEY_UCINET_DIR", unset = path.expand("~/Documents/UCINET data"))
out_dir <- file.path("inst", "extdata")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

write_dataset(
  file.path(ucinet_dir, "synthetic_yesno_36x103.dl"),
  file.path(out_dir, "synthetic_yesno_36x103.csv")
)
write_dataset(
  file.path(ucinet_dir, "synthetic_multiple_choice_36x103_k4.dl"),
  file.path(out_dir, "synthetic_multiple_choice_36x103_k4.csv")
)
write_dataset(
  file.path(ucinet_dir, "synthetic_ordinal_36x103_1to5.dl"),
  file.path(out_dir, "synthetic_ordinal_36x103_1to5.csv")
)

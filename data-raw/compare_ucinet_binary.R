parse_ucinet_text <- function(path) {
  raw <- readBin(path, what = "raw", n = file.info(path)$size)
  chars <- raw[seq.int(3, length(raw), by = 2)]
  txt <- rawToChar(chars)
  txt <- strsplit(txt, "\n", fixed = TRUE)[[1]]
  gsub("\r", "", txt, fixed = TRUE)
}

extract_metric <- function(lines, label) {
  hit <- grep(label, lines, fixed = TRUE, value = TRUE)
  if (!length(hit)) {
    return(NA_real_)
  }
  as.numeric(sub(".*: *", "", hit[1]))
}

weighted_binary_key <- function(x, competence) {
  hi <- max(stats::na.omit(as.vector(x)))
  lo <- min(stats::na.omit(as.vector(x)))
  score <- apply(x, 2, function(col) {
    keep <- !is.na(col)
    if (!any(keep)) {
      return(NA_real_)
    }
    w <- competence[keep]
    p_hi <- sum(w * (col[keep] == hi)) / sum(w)
    ifelse(p_hi >= 0.5, hi, lo)
  })
  score
}

pkg_root <- normalizePath(".")
source(file.path(pkg_root, "R", "utils.R"))
source(file.path(pkg_root, "R", "agreement.R"))
source(file.path(pkg_root, "R", "answer_key.R"))
source(file.path(pkg_root, "R", "consensus.R"))

x <- as.matrix(read.csv(file.path("inst", "extdata", "synthetic_yesno_36x103.csv"), row.names = 1, check.names = FALSE))
fit <- consensus(x, method = "covariance", prior = 0.5)
key <- weighted_binary_key(x, fit$competence[, 1])
log_lines <- parse_ucinet_text(file.path("inst", "extdata", "ucinet_results", "binary_consensus.txt"))

metrics <- data.frame(
  source = c("Romney", "UCINET", "Romney"),
  metric = c("largest_eigenvalue", "largest_eigenvalue", "answer_key_1_count"),
  value = c(fit$eigenvalues[1], extract_metric(log_lines, "Largest eigenvalue"), sum(key == max(key), na.rm = TRUE))
)

print(metrics)

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

pkg_root <- normalizePath(".")
source(file.path(pkg_root, "R", "utils.R"))
source(file.path(pkg_root, "R", "agreement.R"))
source(file.path(pkg_root, "R", "answer_key.R"))
source(file.path(pkg_root, "R", "consensus.R"))

multi <- as.matrix(read.csv(file.path("inst", "extdata", "synthetic_multiple_choice_36x103_k4.csv"), row.names = 1, check.names = FALSE))
ord <- as.matrix(read.csv(file.path("inst", "extdata", "synthetic_ordinal_36x103_1to5.csv"), row.names = 1, check.names = FALSE))

fit_multi <- consensus(multi, method = "formal")
fit_ord <- consensus(ord, method = "informal")

log_multi <- parse_ucinet_text(file.path("inst", "extdata", "ucinet_results", "multiple_consensus.txt"))
log_ord <- parse_ucinet_text(file.path("inst", "extdata", "ucinet_results", "ordinal_consensus.txt"))

out <- rbind(
  data.frame(dataset = "multiple", metric = "largest_eigenvalue", romney = fit_multi$eigenvalues[1], ucinet = extract_metric(log_multi, "Largest eigenvalue")),
  data.frame(dataset = "multiple", metric = "second_eigenvalue", romney = fit_multi$eigenvalues[2], ucinet = extract_metric(log_multi, "2nd largest eigenvalue")),
  data.frame(dataset = "ordinal", metric = "largest_eigenvalue", romney = fit_ord$eigenvalues[1], ucinet = extract_metric(log_ord, "Largest eigenvalue")),
  data.frame(dataset = "ordinal", metric = "second_eigenvalue", romney = fit_ord$eigenvalues[2], ucinet = extract_metric(log_ord, "2nd largest eigenvalue"))
)

print(out)

source(file.path("data-raw", "compare_ucinet.R"))
result <- run_ucinet_comparison()
print(result[result$dataset == "binary", ], row.names = FALSE)

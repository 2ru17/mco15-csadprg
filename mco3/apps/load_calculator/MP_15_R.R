# [BINDING] Dynamic type binding
deadLoad <- 150.5
liveLoad <- 85.0

# [PARAM_PASSING] Pass by value (strictly, copy-on-write optimization in R)
calculateUltimateLoad <- function(dl, ll) {
  return(1.2 * dl + 1.6 * ll)
}

# [DATA_TYPE] Using environments as a composite reference type
# [PARAM_PASSING] Pass by reference effect (sharing) using Environments
distributeLoad <- function(loadEnv, pillars) {
  if (pillars > 0) {
    loadEnv$value <- loadEnv$value / pillars
  }
}

main <- function() {
  ultimateLoadValue <- calculateUltimateLoad(deadLoad, liveLoad)
  totalPillars <- 4
  
  # Create an environment to simulate reference passing
  loadWrapper <- new.env()
  loadWrapper$value <- ultimateLoadValue
  
  distributeLoad(loadWrapper, totalPillars)
  
  # [INTEGRATION] Output formatting and File I/O
  outputStr <- sprintf("Dead Load: %.2f\nLive Load: %.2f\nTotal Pillars: %d\nLoad per Pillar: %.2f\n",
                       deadLoad, liveLoad, totalPillars, loadWrapper$value)
  
  cat(outputStr)
  
  outDir <- "../outputs/R_out"
  if (!dir.exists(outDir)) {
    dir.create(outDir, recursive = TRUE)
  }
  
  outPath <- file.path(outDir, "load_results.txt")
  writeLines(outputStr, outPath)
  
  cat(sprintf("Results saved to %s\n", outPath))
}

main()

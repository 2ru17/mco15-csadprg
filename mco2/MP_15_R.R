# /********************
#  ┃     Last names: Gutang, Wong, Tolentino, Degullado
#  ┃     Language: R
#  ┃     Paradigm(s): Multi-paradigm (Structured, Imperative, Functional)
#  ┃     ********************/
# /**
#  * De La Salle University, Manila
#  * College of Computer Studies
#  * Department of Software Technology
#  *
#  * Course Code: CSADPRG (Advanced Programming)
#  * Major Course Output #2: Data Analysis Pipeline for Flood Control Projects
#  *
#  * File Name: MP_15_R.R
#  * Group Number: 15
#  *
#  * Description:
#  * This R command-line application implements a Data Analysis Pipeline
#  * that ingests DPWH flood control project data from CSV, preprocesses it
#  * (filtering, cleaning, derived field computation), and generates three
#  * tabular reports plus a JSON summary for infrastructure analysis.
#  *
#  * Academic Integrity Statement:
#  * We hereby declare that this submission is our own work and that, to the
#  * best of our knowledge and belief, it contains no material previously
#  * written or published by another person, nor material which has been
#  * accepted for the award of any other degree or diploma, except where due
#  * acknowledgment has been made in the text.
#  */

# CONSTANTS
# CSV column indices (1-based)
COL_MAIN_ISLAND <- 1
COL_REGION <- 2
COL_PROVINCE <- 3
COL_TYPE_OF_WORK <- 9
COL_FUNDING_YEAR <- 10
COL_APPROVED_BUDGET <- 12
COL_CONTRACT_COST <- 13
COL_ACTUAL_COMPLETION <- 14
COL_CONTRACTOR <- 15
COL_START_DATE <- 17
COL_PROJECT_LAT <- 18
COL_PROJECT_LNG <- 19

EXPECTED_COLUMNS <- 22

OUT_DIR <- "R_out"
REPORT1_FILE <- file.path(OUT_DIR, "report1_regional_summary.csv")
REPORT2_FILE <- file.path(OUT_DIR, "report2_contractor_ranking.csv")
REPORT3_FILE <- file.path(OUT_DIR, "report3_annual_trends.csv")
SUMMARY_FILE <- file.path(OUT_DIR, "summary.json")

# APPLICATION STATE
state <- new.env()
state$projects <- data.frame()
state$total_raw_rows <- 0
state$parse_errors <- 0
state$data_loaded <- FALSE

# FORMATTING HELPER
formatNumber <- function(value, decimals) {
  formatC(value, format = "f", digits = decimals, big.mark = ",")
}

padRight <- function(str, width) {
  format(str, width = width, justify = "left")
}

padLeft <- function(str, width) {
  format(str, width = width, justify = "right")
}

# CSV WRITER HELPER
writeCsv <- function(filename, df) {
  write.table(df, file = filename, row.names = FALSE, col.names = TRUE, 
              sep = ",", quote = TRUE, qmethod = "double")
}

# DATA INGESTION
loadData <- function() {
  state$projects <- data.frame()
  state$total_raw_rows <- 0
  state$parse_errors <- 0
  
  filepath <- "dpwh_flood_control_projects.csv"
  if (!file.exists(filepath)) {
    cat(sprintf("Error: Failed to open CSV file: %s\n", filepath))
    return(invisible(NULL))
  }
  
  raw_data <- read.csv(filepath, header = TRUE, stringsAsFactors = FALSE, 
                       na.strings = c("", "NA"), fill = TRUE)
  
  state$total_raw_rows <- nrow(raw_data)
  
  fundingYear <- as.numeric(raw_data[[COL_FUNDING_YEAR]])
  approvedBudget <- as.numeric(raw_data[[COL_APPROVED_BUDGET]])
  contractCost <- as.numeric(raw_data[[COL_CONTRACT_COST]])
  
  startDate <- as.Date(raw_data[[COL_START_DATE]], format="%Y-%m-%d")
  actualCompletionDate <- as.Date(raw_data[[COL_ACTUAL_COMPLETION]], format="%Y-%m-%d")
  
  valid_mask <- !is.na(fundingYear) & fundingYear >= 2021 & fundingYear <= 2023 &
    !is.na(approvedBudget) & !is.na(contractCost) &
    !is.na(startDate) & !is.na(actualCompletionDate) &
    ncol(raw_data) >= EXPECTED_COLUMNS
  
  state$parse_errors <- sum(!valid_mask)
  filtered_data <- raw_data[valid_mask, ]
  
  costSavings <- as.numeric(filtered_data[[COL_APPROVED_BUDGET]]) - as.numeric(filtered_data[[COL_CONTRACT_COST]])
  completionDelayDays <- as.numeric(difftime(as.Date(filtered_data[[COL_ACTUAL_COMPLETION]]), 
                                             as.Date(filtered_data[[COL_START_DATE]]), units = "days"))
  
  projectLat <- as.numeric(filtered_data[[COL_PROJECT_LAT]])
  projectLat[is.na(projectLat)] <- 0.0
  
  projectLng <- as.numeric(filtered_data[[COL_PROJECT_LNG]])
  projectLng[is.na(projectLng)] <- 0.0
  
  projects <- data.frame(
    mainIsland = trimws(filtered_data[[COL_MAIN_ISLAND]]),
    region = trimws(filtered_data[[COL_REGION]]),
    province = trimws(filtered_data[[COL_PROVINCE]]),
    typeOfWork = trimws(filtered_data[[COL_TYPE_OF_WORK]]),
    fundingYear = as.numeric(filtered_data[[COL_FUNDING_YEAR]]),
    approvedBudget = as.numeric(filtered_data[[COL_APPROVED_BUDGET]]),
    contractCost = as.numeric(filtered_data[[COL_CONTRACT_COST]]),
    startDate = as.Date(filtered_data[[COL_START_DATE]]),
    actualCompletionDate = as.Date(filtered_data[[COL_ACTUAL_COMPLETION]]),
    contractor = trimws(filtered_data[[COL_CONTRACTOR]]),
    projectLat = projectLat,
    projectLng = projectLng,
    costSavings = costSavings,
    completionDelayDays = completionDelayDays,
    stringsAsFactors = FALSE
  )
  
  projects <- imputeCoordinates(projects)
  
  state$projects <- projects
  state$data_loaded <- TRUE
  
  cat(sprintf("Processing dataset... (%s rows loaded, %s filtered for 2021-2023)\n", 
              formatNumber(state$total_raw_rows, 0), formatNumber(nrow(projects), 0)))
}

imputeCoordinates <- function(projects) {
  # province -> { latSum, lngSum, count }
  valid_coords <- projects[projects$projectLat != 0.0 & projects$projectLng != 0.0, ]
  
  if (nrow(valid_coords) > 0) {
    prov_lat_avg <- aggregate(projectLat ~ province, data = valid_coords, FUN = mean)
    prov_lng_avg <- aggregate(projectLng ~ province, data = valid_coords, FUN = mean)
    
    for (i in seq_len(nrow(projects))) {
      if (projects$projectLat[i] == 0.0 || projects$projectLng[i] == 0.0) {
        prov <- projects$province[i]
        
        lat_match <- prov_lat_avg$projectLat[prov_lat_avg$province == prov]
        lng_match <- prov_lng_avg$projectLng[prov_lng_avg$province == prov]
        
        if (length(lat_match) > 0 && length(lng_match) > 0) {
          projects$projectLat[i] <- lat_match[1]
          projects$projectLng[i] <- lng_match[1]
        }
      }
    }
  }
  return(projects)
}

# REPORTS
generateAllReports <- function() {
  if (!dir.exists(OUT_DIR)) {
    tryCatch({
      dir.create(OUT_DIR, recursive = TRUE)
    }, error = function(e) {
      cat(sprintf("Error: Failed to create output directory '%s': %s\n", OUT_DIR, e$message))
      return(invisible(NULL))
    })
  }
  
  cat("Generating reports...\nOutputs saved to individual files...\n\n")
  
  generateReport1(state$projects)
  cat("\n")
  generateReport2(state$projects)
  cat("\n")
  generateReport3(state$projects)
  cat("\n")
  generateSummary(state$projects)
}

generateReport1 <- function(projects) {
  # "Region|MainIsland" -> array of indices
  groups <- split(projects, list(projects$region, projects$mainIsland), drop = TRUE)
  
  rows <- lapply(names(groups), function(key) {
    sub_df <- groups[[key]]
    region <- sub_df$region[1]
    mainIsland <- sub_df$mainIsland[1]
    count <- nrow(sub_df)
    
    totalBudget <- sum(sub_df$approvedBudget)
    medianSavings <- median(sub_df$costSavings)
    avgDelay <- mean(sub_df$completionDelayDays)
    highDelayPct <- (sum(sub_df$completionDelayDays > 30) / count) * 100.0
    
    rawScore <- if (avgDelay == 0.0) .Machine$double.xmax else (medianSavings / avgDelay) * 100.0
    
    data.frame(Region = region, MainIsland = mainIsland, TotalBudget = totalBudget, 
               MedianSavings = medianSavings, AvgDelay = avgDelay, HighDelayPct = highDelayPct, 
               rawScore = rawScore, stringsAsFactors = FALSE)
  })
  
  report1_df <- do.call(rbind, rows)
  
  finite_scores <- report1_df$rawScore[is.finite(report1_df$rawScore) & report1_df$rawScore != .Machine$double.xmax]
  
  if (length(finite_scores) > 0) {
    min_score <- min(finite_scores)
    max_score <- max(finite_scores)
    
    report1_df$rawScore[!is.finite(report1_df$rawScore) | report1_df$rawScore == .Machine$double.xmax] <- max_score
    range_val <- max_score - min_score
    
    report1_df$EfficiencyScore <- if (range_val == 0.0) 50.0 else ((report1_df$rawScore - min_score) / range_val) * 100.0
  } else {
    report1_df$EfficiencyScore <- 0.0
  }
  
  report1_df$rawScore <- NULL
  report1_df <- report1_df[order(-report1_df$EfficiencyScore), ]
  
  csv_df <- report1_df
  csv_df$TotalBudget <- sapply(csv_df$TotalBudget, formatNumber, decimals=2)
  csv_df$MedianSavings <- sapply(csv_df$MedianSavings, formatNumber, decimals=2)
  csv_df$AvgDelay <- sapply(csv_df$AvgDelay, formatNumber, decimals=2)
  csv_df$HighDelayPct <- sapply(csv_df$HighDelayPct, formatNumber, decimals=2)
  csv_df$EfficiencyScore <- sapply(csv_df$EfficiencyScore, formatNumber, decimals=2)
  
  writeCsv(REPORT1_FILE, csv_df)
  
  cat("Report 1: Regional Flood Mitigation Efficiency Summary\n")
  cat("Regional Flood Mitigation Efficiency Summary\n")
  cat("(Filtered: 2021-2023 Projects)\n")
  cat(sprintf("| %s | %s | %s | %s | %s | %s | %s |\n", 
              padRight("Region", 45), padRight("MainIsland", 10), padLeft("TotalBudget", 15), 
              padLeft("MedianSavings", 14), padLeft("AvgDelay", 10), 
              padLeft("HighDelayPct", 12), padLeft("EfficiencyScore", 15)))
  
  for (i in 1:min(2, nrow(csv_df))) {
    r <- csv_df[i, ]
    cat(sprintf("| %s | %s | %s | %s | %s | %s | %s |\n", 
                padRight(r$Region, 45), padRight(r$MainIsland, 10), padLeft(r$TotalBudget, 15), 
                padLeft(r$MedianSavings, 14), padLeft(r$AvgDelay, 10), 
                padLeft(r$HighDelayPct, 12), padLeft(r$EfficiencyScore, 15)))
  }
  cat(sprintf("(Full table exported to %s)\n", REPORT1_FILE))
}

generateReport2 <- function(projects) {
  # Contractor -> array of indices
  groups <- split(projects, projects$contractor, drop = TRUE)
  
  rows <- lapply(names(groups), function(contractor) {
    sub_df <- groups[[contractor]]
    if (nrow(sub_df) < 5) return(NULL)
    
    count <- nrow(sub_df)
    totalCost <- sum(sub_df$contractCost)
    totalDelay <- sum(sub_df$completionDelayDays)
    totalSavings <- sum(sub_df$costSavings)
    avgDelay <- totalDelay / count
    
    reliabilityIndex <- if (totalCost == 0.0) 0.0 else (1.0 - (avgDelay / 90.0)) * (totalSavings / totalCost) * 100.0
    reliabilityIndex <- min(reliabilityIndex, 100.0)
    riskFlag <- if (reliabilityIndex < 50.0) "High Risk" else "Low Risk"
    
    data.frame(Contractor = contractor, TotalCost = totalCost, NumProjects = count, 
               AvgDelay = avgDelay, TotalSavings = totalSavings, 
               ReliabilityIndex = reliabilityIndex, RiskFlag = riskFlag, stringsAsFactors = FALSE)
  })
  
  report2_df <- do.call(rbind, rows)
  if (!is.null(report2_df)) {
    report2_df <- report2_df[order(-report2_df$TotalCost), ]
    top15 <- head(report2_df, 15)
    top15 <- cbind(Rank = 1:nrow(top15), top15)
    
    csv_df <- top15
    csv_df$TotalCost <- sapply(csv_df$TotalCost, formatNumber, decimals=2)
    csv_df$AvgDelay <- sapply(csv_df$AvgDelay, formatNumber, decimals=2)
    csv_df$TotalSavings <- sapply(csv_df$TotalSavings, formatNumber, decimals=2)
    csv_df$ReliabilityIndex <- sapply(csv_df$ReliabilityIndex, formatNumber, decimals=2)
    
    writeCsv(REPORT2_FILE, csv_df)
    
    cat("Report 2: Top Contractors Performance Ranking\n")
    cat("Top Contractors Performance Ranking\n")
    cat("(Top 15 by TotalCost, >=5 Projects)\n")
    cat(sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |\n", 
                padLeft("Rank", 4), padRight("Contractor", 45), padLeft("TotalCost", 18), 
                padLeft("NumProjects", 11), padLeft("AvgDelay", 10), padLeft("TotalSavings", 18), 
                padLeft("ReliabilityIndex", 16), padLeft("RiskFlag", 10)))
    
    for (i in 1:min(2, nrow(csv_df))) {
      r <- csv_df[i, ]
      # Truncate contractor string if too long for console display consistency
      cont_str <- if(nchar(r$Contractor) > 45) paste0(substr(r$Contractor, 1, 42), "...") else r$Contractor
      cat(sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |\n", 
                  padLeft(as.character(r$Rank), 4), padRight(cont_str, 45), padLeft(r$TotalCost, 18), 
                  padLeft(as.character(r$NumProjects), 11), padLeft(r$AvgDelay, 10), 
                  padLeft(r$TotalSavings, 18), padLeft(r$ReliabilityIndex, 16), padLeft(r$RiskFlag, 10)))
    }
  } else {
    cat("Report 2: No contractors found with >= 5 projects.\n")
  }
  cat(sprintf("(Full table exported to %s)\n", REPORT2_FILE))
}

generateReport3 <- function(projects) {
  # "FundingYear|TypeOfWork" -> array of indices
  groups <- split(projects, list(projects$fundingYear, projects$typeOfWork), drop = TRUE)
  
  avg_savings_map <- list()
  for (key in names(groups)) {
    avg_savings_map[[key]] <- mean(groups[[key]]$costSavings)
  }
  
  rows <- lapply(names(groups), function(key) {
    sub_df <- groups[[key]]
    year <- sub_df$fundingYear[1]
    typeOfWork <- sub_df$typeOfWork[1]
    totalProjects <- nrow(sub_df)
    
    totalSavings <- sum(sub_df$costSavings)
    overrunCount <- sum(sub_df$costSavings < 0.0)
    
    avgSavings <- totalSavings / totalProjects
    overrunRate <- (overrunCount / totalProjects) * 100.0
    
    yoyChange <- 0.0
    if (year != 2021) {
      prevYear <- year - 1
      prevKey <- paste(prevYear, typeOfWork, sep=".")
      
      if (!is.null(avg_savings_map[[prevKey]])) {
        prevAvg <- avg_savings_map[[prevKey]]
        if (abs(prevAvg) > 0.0) {
          yoyChange <- ((avgSavings - prevAvg) / abs(prevAvg)) * 100.0
        }
      }
    }
    
    data.frame(TypeOfWork = typeOfWork, FundingYear = year, TotalProjects = totalProjects, 
               AvgSavings = avgSavings, OverrunRate = overrunRate, YoYChange = yoyChange, stringsAsFactors = FALSE)
  })
  
  report3_df <- do.call(rbind, rows)
  report3_df <- report3_df[order(report3_df$FundingYear, -report3_df$AvgSavings), ]
  
  csv_df <- report3_df
  csv_df$AvgSavings <- sapply(csv_df$AvgSavings, formatNumber, decimals=2)
  csv_df$OverrunRate <- sapply(csv_df$OverrunRate, formatNumber, decimals=2)
  csv_df$YoYChange <- sapply(csv_df$YoYChange, formatNumber, decimals=2)
  
  writeCsv(REPORT3_FILE, csv_df)
  
  cat("Report 3: Annual Project Type Cost Overrun Trends\n")
  cat("Annual Project Type Cost Overrun Trends\n")
  cat("(Grouped by FundingYear and TypeOfWork)\n")
  cat(sprintf("| %s | %s | %s | %s | %s | %s |\n", 
              padRight("TypeOfWork", 50), padLeft("FundingYear", 11), padLeft("TotalProjects", 13), 
              padLeft("AvgSavings", 15), padLeft("OverrunRate", 11), padLeft("YoYChange", 11)))
  
  for (i in 1:min(3, nrow(csv_df))) {
    r <- csv_df[i, ]
    tw <- if(nchar(r$TypeOfWork) > 50) paste0(substr(r$TypeOfWork, 1, 47), "...") else r$TypeOfWork
    cat(sprintf("| %s | %s | %s | %s | %s | %s |\n", 
                padRight(tw, 50), padLeft(as.character(r$FundingYear), 11), padLeft(as.character(r$TotalProjects), 13), 
                padLeft(r$AvgSavings, 15), padLeft(r$OverrunRate, 11), padLeft(r$YoYChange, 11)))
  }
  cat(sprintf("(Full table exported to %s)\n", REPORT3_FILE))
}

generateSummary <- function(projects) {
  totalProjects <- nrow(projects)
  totalContractors <- length(unique(projects$contractor))
  totalProvinces <- length(unique(projects$province))
  
  totalDelay <- sum(projects$completionDelayDays)
  totalSavings <- sum(projects$costSavings)
  
  globalAvgDelay <- if(totalProjects > 0) totalDelay / totalProjects else 0.0
  
  json_str <- sprintf(
    '{\n  "total_projects": %d,\n  "total_contractors": %d,\n  "total_provinces": %d,\n  "global_avg_delay": %.2f,\n  "total_savings": %.2f\n}',
    totalProjects, totalContractors, totalProvinces, globalAvgDelay, totalSavings
  )
  
  writeLines(json_str, SUMMARY_FILE)
  
  cat(sprintf("Summary Stats (%s):\n", SUMMARY_FILE))
  cat(sprintf('{"total_projects": %d, "total_contractors": %d, "total_provinces": %d, "global_avg_delay": %.2f, "total_savings": %.2f}\n',
              totalProjects, totalContractors, totalProvinces, globalAvgDelay, totalSavings))
}

# MAIN MENU
promptBack <- function() {
  while (TRUE) {
    answer <- toupper(trimws(readline(prompt="Back to Report Selection (Y/N): ")))
    if (answer == "Y") {
      return(TRUE)
    } else if (answer == "N") {
      cat("Exiting program. Goodbye!\n")
      quit(save="no", status=0)
    } else {
      cat("Invalid input. Please enter Y or N.\n")
    }
  }
}

promptMenu <- function() {
  while (TRUE) {
    cat("\nSelect Language Implementation:\n")
    cat("[1] Load the file\n")
    cat("[2] Generate Reports\n")
    cat("[0] Exit\n")
    choice <- trimws(readline(prompt="Enter choice: "))
    
    if (choice == "0") {
      cat("\nExiting program. Goodbye!\n")
      break
    } else if (choice == "1") {
      loadData()
    } else if (choice == "2") {
      if (!state$data_loaded) {
        cat("Error: Please load the file first (option 1).\n")
      } else {
        generateAllReports()
        if (!promptBack()) break
      }
    } else {
      cat("Invalid option. Please enter 0, 1, or 2.\n")
    }
  }
}

# START
if (sys.nframe() == 0L) {
  promptMenu()
}
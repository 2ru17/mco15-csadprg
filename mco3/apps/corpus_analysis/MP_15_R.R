# [PARAM_PASSING] Pass by value (strictly, copy-on-write)
tokenize <- function(text) {
  # [DATA_TYPE] Character vectors manipulation
  lower_text <- tolower(text)
  clean_text <- gsub("[^a-z0-9[:space:]]", "", lower_text)
  words <- unlist(strsplit(clean_text, "[[:space:]]+"))
  words <- words[words != ""]
  return(words)
}

# [BINDING] Dynamic binding with R tables/lists.
countFrequencies <- function(words) {
  # table() creates a frequency table
  freq_table <- table(words)
  return(freq_table)
}

main <- function() {
  corpusPath <- "corpora/sample_corpus.txt"
  if (file.exists(corpusPath)) {
    text <- paste(readLines(corpusPath, warn = FALSE), collapse = " ")
  } else {
    text <- "default text fallback"
  }
  
  words <- tokenize(text)
  freq_table <- countFrequencies(words)
  
  # Sort frequencies descending
  sorted_freq <- sort(freq_table, decreasing = TRUE)
  
  outputStr <- "Corpus Word Frequencies:\n"
  for (word in names(sorted_freq)) {
    outputStr <- paste0(outputStr, sprintf("%s: %d\n", word, sorted_freq[[word]]))
  }
  
  cat(outputStr)
  
  # [INTEGRATION] File I/O
  outDir <- "../outputs/R_out"
  if (!dir.exists(outDir)) {
    dir.create(outDir, recursive = TRUE)
  }
  
  outPath <- file.path(outDir, "corpus_results.txt")
  writeLines(outputStr, outPath)
  
  cat(sprintf("Results saved to %s\n", outPath))
}

main()

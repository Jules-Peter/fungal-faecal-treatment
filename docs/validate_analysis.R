#!/usr/bin/env Rscript
# Validation script for fungal treatment analysis
# This script checks that all dependencies and data are available

library(here)

cat("=== FUNGAL TREATMENT ANALYSIS VALIDATION ===\n\n")

# Check R packages
required_packages <- c("tidyverse", "here", "lubridate", "ggplot2", "scales", "knitr", "rmarkdown", "googlesheets4", "lme4", "lmerTest", "emmeans")
missing_packages <- character()

for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

if(length(missing_packages) > 0) {
  cat("MISSING PACKAGES:\n")
  cat("Install these packages before running the analysis:\n")
  cat("install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n\n")
} else {
  cat("✓ All required R packages are installed\n\n")
}

# Check data file
data_path <- here("data", "processed", "experiment_final.csv")

if(file.exists(data_path)) {
  cat("✓ Data file found at:", data_path, "\n")
  
  # Quick data check
  data <- read.csv(data_path)
  cat("  - Observations:", nrow(data), "\n")
  cat("  - Species:", length(unique(data$species)), "\n")
  cat("  - Columns:", ncol(data), "\n")
  
  data_found <- TRUE
} else {
  data_found <- FALSE
}

if(!data_found) {
  cat("✗ Data file not found!\n")
  cat("Expected location:", data_path, "\n")
  cat("\nPlease run the data download and cleaning scripts first:\n")
  cat("  Rscript", here("R", "01-data_download.R"), "\n")
  cat("  Rscript", here("R", "data_cleaning_new.R"), "\n")
}

# Check main analysis file
analysis_file <- here("docs", "fungal_treatment_simplified.qmd")
if(file.exists(analysis_file)) {
  cat("✓ Main analysis file found:", analysis_file, "\n")
  analysis_found <- TRUE
} else {
  cat("✗ Main analysis file missing:", analysis_file, "\n")
  analysis_found <- FALSE
}

cat("\n=== VALIDATION COMPLETE ===\n")

if(length(missing_packages) == 0 && data_found && analysis_found) {
  cat("🎉 All components ready! You can run the analysis.\n")
  cat("\nTo run the complete pipeline:\n")
  cat("  Rscript", here("run_analysis.R"), "\n")
  cat("\nOr to generate just the report:\n")
  cat("  cd", here("docs"), "&& quarto render fungal_treatment_simplified.qmd\n")
  cat("  # or\n")
  cat("  Rscript -e \"rmarkdown::render('", analysis_file, "')\"\n", sep="")
} else {
  cat("⚠️  Please address the issues above before running the analysis.\n")
}
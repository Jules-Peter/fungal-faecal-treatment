#!/usr/bin/env Rscript
# Validation script for fungal treatment analysis
# This script checks that all dependencies and data are available

cat("=== FUNGAL TREATMENT ANALYSIS VALIDATION ===\n\n")

# Check R packages
required_packages <- c("tidyverse", "ggplot2", "scales", "knitr", "lme4", "lmerTest", "emmeans")
missing_packages <- c()

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
data_paths <- c(
  "../data/processed/experiment_final.csv",
  "data/processed/experiment_final.csv",
  "/mnt/c/Users/jupeter/gitrepos/fungal-faecal-treatment/data/processed/experiment_final.csv"
)

data_found <- FALSE
for(path in data_paths) {
  if(file.exists(path)) {
    cat("✓ Data file found at:", path, "\n")
    
    # Quick data check
    data <- read.csv(path)
    cat("  - Observations:", nrow(data), "\n")
    cat("  - Species:", length(unique(data$species)), "\n")
    cat("  - Columns:", ncol(data), "\n")
    
    data_found <- TRUE
    break
  }
}

if(!data_found) {
  cat("✗ Data file not found!\n")
  cat("Expected locations:\n")
  for(path in data_paths) {
    cat("  -", path, "\n")
  }
}

# Check main analysis file
if(file.exists("fungal_treatment_simplified.qmd")) {
  cat("✓ Main analysis file found: fungal_treatment_simplified.qmd\n")
} else {
  cat("✗ Main analysis file missing: fungal_treatment_simplified.qmd\n")
}

cat("\n=== VALIDATION COMPLETE ===\n")

if(length(missing_packages) == 0 && data_found && file.exists("fungal_treatment_simplified.qmd")) {
  cat("🎉 All components ready! You can run the analysis.\n")
  cat("\nTo generate the report:\n")
  cat("quarto render fungal_treatment_simplified.qmd\n")
  cat("# or\n")
  cat("Rscript -e \"rmarkdown::render('fungal_treatment_simplified.qmd')\"\n")
} else {
  cat("⚠️  Please address the issues above before running the analysis.\n")
}
#!/usr/bin/env Rscript

# Run analysis pipeline

cat("=== Fungal Treatment Analysis Pipeline ===\n\n")

# Step 1: Download raw data
cat("Step 1: Downloading raw data from Google Sheets...\n")
source("R/01-data_download.R")

# Step 2: Clean the data
cat("\nStep 2: Cleaning and processing data...\n")
source("R/data_cleaning_new.R")

# Step 3: Render the analysis report
cat("\nStep 3: Rendering analysis report...\n")
library(rmarkdown)
setwd("docs")
render("fungal_treatment_simplified.qmd", output_format = "html_document")

cat("\n=== Analysis complete! ===\n")
cat("Report saved as: docs/fungal_treatment_simplified.html\n")
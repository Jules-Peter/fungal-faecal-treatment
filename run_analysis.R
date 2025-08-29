#!/usr/bin/env Rscript

# Run analysis pipeline
library(here)

cat("=== Fungal Treatment Analysis Pipeline ===\n\n")

# Step 1: Download raw data
cat("Step 1: Downloading raw data from Google Sheets...\n")
source(here("R", "01-data_download.R"))

# Step 2: Clean the data
cat("\nStep 2: Cleaning and processing data...\n")
source(here("R", "data_cleaning_new.R"))

# Step 3: Render the analysis report
cat("\nStep 3: Rendering analysis report...\n")
library(rmarkdown)

# Check if the Quarto document exists
qmd_path <- here("docs", "fungal_treatment_simplified.qmd")
if(file.exists(qmd_path)) {
  render(qmd_path, output_format = "html_document")
} else {
  cat("Error: fungal_treatment_simplified.qmd not found in docs/\n")
  cat("Please ensure the analysis document exists before running.\n")
}

if(file.exists(qmd_path)) {
  cat("\n=== Analysis complete! ===\n")
  cat("Report saved as:", here("docs", "fungal_treatment_simplified.html"), "\n")
} else {
  cat("\n=== Analysis incomplete due to missing files ===\n")
}
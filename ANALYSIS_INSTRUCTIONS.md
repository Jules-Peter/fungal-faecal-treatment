# Analysis Instructions

## Prerequisites

Make sure you have R installed with the following packages:
- tidyverse
- googlesheets4
- rmarkdown
- quarto (if using Quarto instead of rmarkdown)
- All packages listed in the analysis document

## Running the Analysis

### Option 1: Run the complete pipeline (Recommended)

```r
source("run_analysis.R")
```

This will:
1. Download raw data from Google Sheets
2. Clean and process the data
3. Generate the analysis report

### Option 2: Run steps manually

1. **Download raw data:**
   ```r
   source("R/01-data_download.R")
   ```

2. **Clean the data:**
   ```r
   source("R/data_cleaning_new.R")
   ```

3. **Generate the report:**
   ```r
   setwd("docs")
   rmarkdown::render("fungal_treatment_simplified.qmd")
   # OR if using Quarto:
   # quarto::quarto_render("fungal_treatment_simplified.qmd")
   ```

## Troubleshooting

### Error: "Could not find or load experiment_final.csv"
- Make sure you've run the data download and cleaning scripts first
- Check that the `data/processed/` directory contains the processed CSV files

### Google Sheets authentication
- You may need to authenticate with Google on first run
- Follow the prompts in your R console

### Missing packages
- Install any missing packages using:
  ```r
  install.packages(c("tidyverse", "googlesheets4", "rmarkdown", "lme4", "lmerTest", "emmeans"))
  ```

## Output

The final analysis report will be saved as:
- `docs/fungal_treatment_simplified.html`

## Data Files

After running the scripts, you should have:
- Raw data in `data/raw/`
- Processed data in `data/processed/` including:
  - `experiment_final.csv` (main analysis file)
  - `bacteria_cleaned.csv`
  - `faeces_cleaned.csv`
  - `growth_speed_cleaned.csv`
  - `inoculum_cleaned.csv`
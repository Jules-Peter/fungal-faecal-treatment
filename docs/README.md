# Analysis Documentation

This directory contains the analysis files for the fungal fecal treatment study.

## Files

### Primary Analysis
- `fungal_treatment_simplified.qmd` - **Main analysis document** (publication-ready)
  - Comprehensive evaluation of fungal species for growth and antimicrobial effectiveness
  - Includes proper statistical analysis with control comparisons
  - Generates publication-quality figures and tables

### Legacy/Archive
- `area_size_analysis.qmd` - Original exploratory analysis (archived)
- `fungal_treatment_analysis.qmd` - Intermediate version (archived)

### Documentation
- `ANALYSIS_IMPROVEMENTS_SUMMARY.md` - Detailed summary of improvements made
- `apa.csl` - Citation style file for academic formatting

## Usage

### Generate the Analysis Report
```bash
# Using Quarto (recommended)
quarto render fungal_treatment_simplified.qmd

# Using R/RStudio
Rscript -e "rmarkdown::render('fungal_treatment_simplified.qmd')"
```

### Requirements
- R packages: `tidyverse`, `ggplot2`, `scales`, `knitr`
- Data file: `../data/processed/experiment_final.csv`

## Output
- HTML report with interactive visualizations
- Publication-ready figures and tables
- Statistical analysis results with proper control comparisons

## Notes
- HTML output files and associated folders are gitignored (regenerate as needed)
- Main analysis focuses on species with sufficient data for robust conclusions
- Legacy files preserved for reference but not recommended for use
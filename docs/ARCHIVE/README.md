# Archived Analysis Files

This folder contains previous versions of the analysis for reference.

## Files

- `area_size_analysis.qmd` - Original exploratory analysis
  - Contains redundant visualizations and statistical approaches
  - Mixed statistical methods (ANOVA + mixed models)
  - Incomplete handling of replicate structure

- `fungal_treatment_analysis.qmd` - First attempt at publication-ready format
  - Comprehensive but overly complex
  - Data handling issues with actual dataset
  - Correlation errors due to insufficient data validation

## Why Archived

These files represent the development process but are not recommended for use:
1. **Data compatibility issues** - Don't handle the actual CSV structure properly
2. **Statistical inconsistencies** - Mix different analytical approaches
3. **Reproducibility problems** - Complex dependencies and error-prone code
4. **Presentation issues** - Overly complex for the available data

## Current Recommendation

Use `../fungal_treatment_simplified.qmd` which addresses all these issues with:
- Robust data handling
- Consistent statistical approach  
- Clear presentation appropriate for the data
- Proper error handling and validation
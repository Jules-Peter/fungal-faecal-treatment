###This file will load the data into the raw folder

###install needed packages
library("tidyverse")
library("googlesheets4")

###Reading the files from google drive 
bacteria_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/1HEGDEres6dtpPC9Hlje8mq1gSiPV5tv6HVcqMCTcm7Q/edit?usp=drive_link")
experiment_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/1LAyaN5P7wxgKNc9Acbh59-fOWWVrjkTOBtTCqOmxAc8/edit?usp=drive_link")
faeces_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/15zEkXV1cOHz2bjWpk8h_SMbINThnYcgxCV30DCnaMOo/edit?usp=drive_link")
growth_speed_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/14VSVuUM32Q5M2XNoXCCtOmAFMrl_rKPtyenp6XVz_dg/edit?usp=drive_link")
inoculum_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/1A6j-FTdwOlPrr494TVFlIqkjl4RCOjVuNB03TEnBH2M/edit?usp=drive_link")

# Function to safely convert list columns to numeric
safe_numeric <- function(x) {
  if (is.list(x)) {
    # Extract values from list column
    x <- sapply(x, function(val) {
      if (is.null(val) || length(val) == 0) {
        return(NA)
      } else {
        return(as.numeric(val[[1]]))
      }
    })
  }
  return(as.numeric(x))
}

# Fix experiment_1_1 list columns that should be numeric
experiment_1_1 <- experiment_1_1 %>%
  mutate(
    ph_14dpi = safe_numeric(ph_14dpi),
    weight_14dpi = safe_numeric(weight_14dpi),
    water_content_14dpi = safe_numeric(water_content_14dpi),
    weight_0dpi = safe_numeric(weight_0dpi)
  )

# Fix faeces_1_1 list columns that should be numeric
faeces_1_1 <- faeces_1_1 %>%
  mutate(
    ph = safe_numeric(ph),
    water_content_0dpi = safe_numeric(water_content_0dpi),
    sample_weight_1 = safe_numeric(sample_weight_1),
    sample_weight_2 = safe_numeric(sample_weight_2),
    sample_weight_3 = safe_numeric(sample_weight_3),
    dilution_factor_ecoli = safe_numeric(dilution_factor_ecoli),
    dilution_factor_enterococcus = safe_numeric(dilution_factor_enterococcus),
    e_coli_counted_1 = safe_numeric(e_coli_counted_1),
    e_coli_counted_2 = safe_numeric(e_coli_counted_2),
    e_coli_counted_3 = safe_numeric(e_coli_counted_3),
    enterococcus_counted_1 = safe_numeric(enterococcus_counted_1),
    enterococcus_counted_2 = safe_numeric(enterococcus_counted_2),
    enterococcus_counted_3 = safe_numeric(enterococcus_counted_3)
  )

# Fix bacteria_1_1 list columns that should be numeric
bacteria_1_1 <- bacteria_1_1 %>%
  mutate(
    sample_weight = safe_numeric(sample_weight),
    dilution_ecoli = safe_numeric(dilution_ecoli),
    ecoli_counted = safe_numeric(ecoli_counted)
  )

# Fix growth_speed_1_1 list columns that should be numeric  
growth_speed_1_1 <- growth_speed_1_1 %>%
  mutate(
    area_size = safe_numeric(area_size)
  )

# Check data summary
cat("\nData import summary:\n")
cat("experiment_1_1 - Non-NA pH_14dpi values:", sum(!is.na(experiment_1_1$ph_14dpi)), "\n")
cat("experiment_1_1 - Non-NA weight_14dpi values:", sum(!is.na(experiment_1_1$weight_14dpi)), "\n")
cat("faeces_1_1 - Non-NA pH values:", sum(!is.na(faeces_1_1$ph)), "\n")
cat("faeces_1_1 - Non-NA water_content_0dpi values:", sum(!is.na(faeces_1_1$water_content_0dpi)), "\n")
cat("faeces_1_1 - pH range:", round(min(faeces_1_1$ph, na.rm = TRUE), 2), "to", round(max(faeces_1_1$ph, na.rm = TRUE), 2), "\n")

###Writing the files in git hup directory follow up
# Use na = "NA" to write NA values as "NA" string instead of empty
write_csv(bacteria_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/bacteria_1_1.csv", na = "NA")
write_csv(experiment_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/experiment_1_1.csv", na = "NA")
write_csv(faeces_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/faeces_1_1.csv", na = "NA")
write_csv(growth_speed_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/growth_speed_1_1.csv", na = "NA")
write_csv(inoculum_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/inoculum_1_1.csv", na = "NA")

cat("\nAll files saved successfully!\n")



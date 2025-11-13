# ============================================
# Data Processing Script - Experiment 1_2 Only
# Created: 2025-11-11
# Purpose: Clean and process data for fungal faecal treatment experiment 1_2
# ============================================

# Load required libraries
library(tidyverse)

# ============================================
# PROCESS RAW DATA FILES
# ============================================

# Process bacteria data
bacteria_1_2 <- read.csv("data/raw/bacteria_1_2.csv") %>%
  mutate(ecoli_conc = ecoli_counted * dilution_ecoli / sample_weight) %>%
  select(id_treatment, ecoli_conc)

write.csv(bacteria_1_2, "data/processed/bacteria_1_2_processed.csv", row.names = FALSE)

# Process faeces data
faeces_1_2 <- read.csv("data/raw/faeces_1_2.csv") %>%
  mutate(
    # Calculate E. coli concentrations for each replicate
    ecoli_conc_1 = e_coli_counted_1 * dilution_factor_ecoli / sample_weight_1,
    ecoli_conc_2 = e_coli_counted_2 * dilution_factor_ecoli / sample_weight_2,
    ecoli_conc_3 = e_coli_counted_3 * dilution_factor_ecoli / sample_weight_3,
    # Calculate mean E. coli concentration
    ecoli_conc_mean = rowMeans(cbind(ecoli_conc_1, ecoli_conc_2, ecoli_conc_3), na.rm = TRUE)
  ) %>%
  select(id_faeces, ecoli_conc_mean, water_content_0dpi, ph) %>%
  rename(ph_0dpi = ph, ecoli_conc_mean_0dpi = ecoli_conc_mean)

write.csv(faeces_1_2, "data/processed/faeces_1_2_processed.csv", row.names = FALSE)

# Process growth speed data
growth_speed_1_2 <- read.csv("data/raw/growth_speed_1_2.csv") %>%
  mutate(date = as.Date(date)) %>%
  group_by(id_treatment) %>%
  mutate(
    first_date = min(date),
    dpi = as.numeric(date - first_date)
  ) %>%
  ungroup() %>%
  # Keep only 7 and 14 DPI measurements
  filter(dpi %in% c(7, 14)) %>%
  select(id_treatment, dpi, area_size, contamination_area, growth_description) %>%
  # Average multiple measurements per timepoint
  group_by(id_treatment, dpi) %>%
  summarise(
    area_size = mean(area_size, na.rm = TRUE),
    contamination_area = mean(contamination_area, na.rm = TRUE),
    growth_description = first(growth_description),
    .groups = "drop"
  ) %>%
  # Pivot to wide format
  pivot_wider(
    names_from = dpi,
    values_from = c(area_size, contamination_area, growth_description),
    names_sep = "_"
  ) %>%
  rename_with(~ paste0(.x, "dpi"), matches("area_size_|contamination_area_|growth_description_"))

write.csv(growth_speed_1_2, "data/processed/growth_speed_1_2_processed.csv", row.names = FALSE)

# ============================================
# JOIN DATA WITH EXPERIMENT TABLE
# ============================================

# Read main experiment table and inoculum data
experiment_1_2 <- read.csv("data/raw/experiment_1_2.csv")
inoculum_1_2 <- read.csv("data/raw/inoculum_1_2.csv") %>%
  select(id_inoc, species, production_date)

# Join all data together
experiment_1_2_joined <- experiment_1_2 %>%
  left_join(growth_speed_1_2, by = "id_treatment") %>%
  left_join(bacteria_1_2, by = "id_treatment") %>%
  left_join(faeces_1_2, by = "id_faeces") %>%
  left_join(inoculum_1_2, by = "id_inoc")

# ============================================
# FILTER BY SELECTED SPECIES
# ============================================

selected_species <- c(
  "F35 Sordaria",
  "G. lucidum", 
  "P. ostreatus columbinus",
  "F15 Faecal isolate 1",
  "F31 Mucor spp I3",
  "T. harzianum CBS245.93",
  "T. harzianum T22",
  "T. koningii",
  "Coprinus comata",
  "F40",
  "P. ostreatus",
  "P. ostreatus v. Floridae",
  "P. ostreatus v.F",
  "ctrl"
)

# Filter and add calculated columns
experiment_1_2_filtered <- experiment_1_2_joined %>%
  filter(species %in% selected_species) %>%
  mutate(
    # Classify growth status at 14 DPI
    growth_status_14dpi = case_when(
      # No growth if area < 15
      is.na(area_size_14dpi) | area_size_14dpi < 15 ~ case_when(
        is.na(contamination_area_14dpi) | contamination_area_14dpi < 10 ~ "No growth, no contamination",
        contamination_area_14dpi >= 10 ~ "No growth, contaminated"
      ),
      # Growth present (area >= 15)
      area_size_14dpi >= 15 ~ case_when(
        is.na(contamination_area_14dpi) | contamination_area_14dpi < area_size_14dpi ~ "Growth, no contamination",
        contamination_area_14dpi >= area_size_14dpi ~ "Growth, contaminated"
      ),
      TRUE ~ "Other"
    ),
    
    # Calculate dry weights (water content is in decimal form 0-1)
    dry_weight_0dpi = case_when(
      !is.na(weight_0dpi) & !is.na(water_content_0dpi) & water_content_0dpi < 1 ~ 
        weight_0dpi * (1 - water_content_0dpi),
      TRUE ~ NA_real_
    ),
    dry_weight_14dpi = case_when(
      !is.na(weight_14dpi) & !is.na(water_content_14dpi) & water_content_14dpi < 1 ~ 
        weight_14dpi * (1 - water_content_14dpi),
      TRUE ~ NA_real_
    ),
    
    # Calculate weight changes
    dry_weight_change = dry_weight_14dpi - dry_weight_0dpi,
    dry_weight_percent_change = case_when(
      !is.na(dry_weight_0dpi) & dry_weight_0dpi > 0 ~ 
        (dry_weight_change / dry_weight_0dpi) * 100,
      TRUE ~ NA_real_
    ),
    weight_percent_change = case_when(
      !is.na(weight_0dpi) & weight_0dpi > 0 ~ 
        ((weight_14dpi - weight_0dpi) / weight_0dpi) * 100,
      TRUE ~ NA_real_
    )
  )

# Save the full filtered dataset
write.csv(experiment_1_2_filtered, "data/processed/experiment_1_2_joined.csv", row.names = FALSE)

# ============================================
# CREATE SPECIALIZED DATASET FOR ANALYSIS
# ============================================

# Filter for pH/weight/E.coli analyses
# Keep controls that didn't grow AND fungal species that did grow
experiment_1_2_analysis <- experiment_1_2_filtered %>%
  filter(
    # Controls: keep those without successful fungal growth
    (species == "ctrl" & growth_status_14dpi %in% c(
      "No growth, no contamination", 
      "No growth, contaminated", 
      "Growth, contaminated"
    )) |
    # Fungal species: keep only those with growth
    (species != "ctrl" & growth_status_14dpi %in% c(
      "Growth, no contamination", 
      "Growth, contaminated"
    ))
  )

# Save the analysis dataset
write.csv(experiment_1_2_analysis, "data/processed/experiment_1_2_ph_weight_ecoli.csv", row.names = FALSE)

# ============================================
# PRINT SUMMARY STATISTICS
# ============================================

cat("\n=== DATA PROCESSING SUMMARY ===\n")
cat("Total samples after species filtering:", nrow(experiment_1_2_filtered), "\n")
cat("Samples in analysis dataset:", nrow(experiment_1_2_analysis), "\n")
cat("\nSamples by growth status (analysis dataset):\n")
print(table(experiment_1_2_analysis$growth_status_14dpi, experiment_1_2_analysis$species))

# Check missing data
cat("\n=== MISSING DATA SUMMARY ===\n")
cat("Samples with weight_14dpi:", sum(!is.na(experiment_1_2_analysis$weight_14dpi)), "\n")
cat("Samples with dry_weight_14dpi:", sum(!is.na(experiment_1_2_analysis$dry_weight_14dpi)), "\n")
cat("Missing dry weight despite having wet weight:", 
    sum(!is.na(experiment_1_2_analysis$weight_14dpi) & is.na(experiment_1_2_analysis$dry_weight_14dpi)), "\n")
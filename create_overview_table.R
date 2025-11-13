# Create comprehensive overview table from raw datasets
# This script combines all raw data files to create a complete overview

library(tidyverse)

# Load all raw datasets
cat("Loading raw datasets...\n")
experiment_1_2 <- read_csv("data/raw/experiment_1_2.csv", show_col_types = FALSE)
bacteria_1_2 <- read_csv("data/raw/bacteria_1_2.csv", show_col_types = FALSE)
faeces_1_2 <- read_csv("data/raw/faeces_1_2.csv", show_col_types = FALSE)
growth_speed_1_2 <- read_csv("data/raw/growth_speed_1_2.csv", show_col_types = FALSE)
inoculum_1_2 <- read_csv("data/raw/inoculum_1_2.csv", show_col_types = FALSE)

# Display structure of each dataset
cat("\n=== Experiment 1_2 Structure ===\n")
cat("Dimensions:", nrow(experiment_1_2), "x", ncol(experiment_1_2), "\n")
cat("Columns:", paste(names(experiment_1_2), collapse = ", "), "\n")

cat("\n=== Bacteria 1_2 Structure ===\n")
cat("Dimensions:", nrow(bacteria_1_2), "x", ncol(bacteria_1_2), "\n")
cat("Columns:", paste(names(bacteria_1_2), collapse = ", "), "\n")

cat("\n=== Faeces 1_2 Structure ===\n")
cat("Dimensions:", nrow(faeces_1_2), "x", ncol(faeces_1_2), "\n")
cat("Columns:", paste(names(faeces_1_2), collapse = ", "), "\n")

cat("\n=== Growth Speed 1_2 Structure ===\n")
cat("Dimensions:", nrow(growth_speed_1_2), "x", ncol(growth_speed_1_2), "\n")
cat("Columns:", paste(names(growth_speed_1_2), collapse = ", "), "\n")

cat("\n=== Inoculum 1_2 Structure ===\n")
cat("Dimensions:", nrow(inoculum_1_2), "x", ncol(inoculum_1_2), "\n")
cat("Columns:", paste(names(inoculum_1_2), collapse = ", "), "\n")

# Create overview by dataset
overview_list <- list()

# 1. Main experiment data overview
overview_list$experiment_summary <- experiment_1_2 %>%
  summarise(
    dataset = "experiment_1_2",
    total_records = n(),
    unique_treatments = n_distinct(id_treatment, na.rm = TRUE),
    unique_species = n_distinct(species, na.rm = TRUE),
    species_list = paste(sort(unique(species)), collapse = ", "),
    date_range = paste(min(date_sampling, na.rm = TRUE), "to", max(date_sampling, na.rm = TRUE))
  )

# 2. Bacteria data overview
overview_list$bacteria_summary <- bacteria_1_2 %>%
  summarise(
    dataset = "bacteria_1_2",
    total_records = n(),
    unique_faeces_ids = n_distinct(id_faeces, na.rm = TRUE),
    mean_ecoli_conc = round(mean(ecoli_conc, na.rm = TRUE), 2),
    sd_ecoli_conc = round(sd(ecoli_conc, na.rm = TRUE), 2),
    min_ecoli = min(ecoli_conc, na.rm = TRUE),
    max_ecoli = max(ecoli_conc, na.rm = TRUE)
  )

# 3. Faeces data overview
overview_list$faeces_summary <- faeces_1_2 %>%
  summarise(
    dataset = "faeces_1_2",
    total_records = n(),
    unique_faeces_ids = n_distinct(id_faeces, na.rm = TRUE),
    mean_ph = round(mean(ph, na.rm = TRUE), 2),
    mean_water_content = round(mean(water_content, na.rm = TRUE), 2),
    mean_weight = round(mean(weight, na.rm = TRUE), 2)
  )

# 4. Growth speed overview
overview_list$growth_speed_summary <- growth_speed_1_2 %>%
  summarise(
    dataset = "growth_speed_1_2",
    total_records = n(),
    unique_treatments = n_distinct(id_treatment, na.rm = TRUE),
    mean_area_7dpi = round(mean(area_size_7dpi, na.rm = TRUE), 2),
    mean_area_14dpi = round(mean(area_size_14dpi, na.rm = TRUE), 2),
    mean_contamination_7dpi = round(mean(contamination_7dpi, na.rm = TRUE), 2),
    mean_contamination_14dpi = round(mean(contamination_14dpi, na.rm = TRUE), 2)
  )

# 5. Inoculum overview
overview_list$inoculum_summary <- inoculum_1_2 %>%
  summarise(
    dataset = "inoculum_1_2",
    total_records = n(),
    unique_inoculum_ids = n_distinct(id_inoculum, na.rm = TRUE),
    unique_species = n_distinct(species, na.rm = TRUE)
  )

# Combine all summaries
overview_combined <- bind_rows(overview_list, .id = "summary_type")

# Create detailed species overview from main experiment data
species_overview <- experiment_1_2 %>%
  group_by(species) %>%
  summarise(
    n_plates = n(),
    n_faeces_samples = n_distinct(id_faeces, na.rm = TRUE),
    n_inoculum_types = n_distinct(id_inoculum, na.rm = TRUE),
    growth_7dpi_count = sum(growth_description_7dpi > 0, na.rm = TRUE),
    growth_14dpi_count = sum(growth_description_14dpi > 0, na.rm = TRUE),
    mean_weight_0dpi = round(mean(weight_0dpi, na.rm = TRUE), 2),
    mean_weight_14dpi = round(mean(weight_14dpi, na.rm = TRUE), 2),
    mean_ph_0dpi = round(mean(ph_0dpi, na.rm = TRUE), 2),
    mean_ph_14dpi = round(mean(ph_14dpi, na.rm = TRUE), 2),
    n_missing_weight = sum(is.na(weight_14dpi)),
    n_missing_ph = sum(is.na(ph_14dpi)),
    .groups = "drop"
  ) %>%
  arrange(desc(n_plates))

# Create treatment-level detail table
treatment_detail <- experiment_1_2 %>%
  select(id_treatment, species, id_faeces, id_inoculum, 
         growth_description_7dpi, growth_description_14dpi,
         area_size_7dpi, area_size_14dpi,
         contamination_7dpi, contamination_14dpi,
         weight_0dpi, weight_14dpi, ph_0dpi, ph_14dpi) %>%
  arrange(species, id_treatment)

# Save all tables
cat("\nSaving overview tables...\n")
write_csv(overview_combined, "data/processed/dataset_overview_summary.csv")
write_csv(species_overview, "data/processed/species_overview_raw.csv")
write_csv(treatment_detail, "data/processed/treatment_detail_raw.csv")

# Also save as Excel file with multiple sheets for easier viewing
library(openxlsx)
wb <- createWorkbook()
addWorksheet(wb, "Dataset Summary")
addWorksheet(wb, "Species Overview")
addWorksheet(wb, "Treatment Details")

writeData(wb, "Dataset Summary", overview_combined)
writeData(wb, "Species Overview", species_overview)
writeData(wb, "Treatment Details", treatment_detail)

saveWorkbook(wb, "data/processed/raw_data_overview.xlsx", overwrite = TRUE)

# Print summary to console
cat("\n=== OVERVIEW SUMMARY ===\n")
cat("Total plates in experiment:", nrow(experiment_1_2), "\n")
cat("Unique species:", n_distinct(experiment_1_2$species), "\n")
cat("Species list:", paste(sort(unique(experiment_1_2$species)), collapse = ", "), "\n")
cat("\nFiles created:\n")
cat("- data/processed/dataset_overview_summary.csv\n")
cat("- data/processed/species_overview_raw.csv\n")
cat("- data/processed/treatment_detail_raw.csv\n")
cat("- data/processed/raw_data_overview.xlsx (Excel file with all tables)\n")
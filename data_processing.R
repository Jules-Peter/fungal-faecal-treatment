# Data Processing Script
# Created: 2025-10-16

# Load required libraries
library(tidyverse)

# Set working directory (adjust as needed)
# setwd("/path/to/your/project")

# Process bacteria data (file 1_1)
bacteria_1_1 <- read.csv("data/raw/bacteria_1_1.csv") %>%
  mutate(ecoli_conc = ecoli_counted * dilution_ecoli / sample_weight) %>%
  select(id_treatment, ecoli_conc)

# Save processed bacteria data (file 1_1)
write.csv(bacteria_1_1, "data/processed/bacteria_1_1_processed.csv", row.names = FALSE)

# Process bacteria data (file 1_2)
bacteria_1_2 <- read.csv("data/raw/bacteria_1_2.csv") %>%
  mutate(ecoli_conc = ecoli_counted * dilution_ecoli / sample_weight) %>%
  select(id_treatment, ecoli_conc)

# Save processed bacteria data (file 1_2)
write.csv(bacteria_1_2, "data/processed/bacteria_1_2_processed.csv", row.names = FALSE)

# Process faeces data (file 1_1)
faeces_1_1 <- read.csv("data/raw/faeces_1_1.csv") %>%
  mutate(
    ecoli_conc_1 = e_coli_counted_1 * dilution_factor_ecoli / sample_weight_1,
    ecoli_conc_2 = e_coli_counted_2 * dilution_factor_ecoli / sample_weight_2,
    ecoli_conc_3 = e_coli_counted_3 * dilution_factor_ecoli / sample_weight_3,
    ecoli_conc_mean = rowMeans(cbind(ecoli_conc_1, ecoli_conc_2, ecoli_conc_3), na.rm = TRUE)
  ) %>%
  select(id_faeces, ecoli_conc_mean, water_content_0dpi, ph) %>%
  rename(ph_0dpi = ph, ecoli_conc_mean_0dpi = ecoli_conc_mean)

# Save processed faeces data (file 1_1)
write.csv(faeces_1_1, "data/processed/faeces_1_1_processed.csv", row.names = FALSE)

# Process faeces data (file 1_2)
faeces_1_2 <- read.csv("data/raw/faeces_1_2.csv") %>%
  mutate(
    ecoli_conc_1 = e_coli_counted_1 * dilution_factor_ecoli / sample_weight_1,
    ecoli_conc_2 = e_coli_counted_2 * dilution_factor_ecoli / sample_weight_2,
    ecoli_conc_3 = e_coli_counted_3 * dilution_factor_ecoli / sample_weight_3,
    ecoli_conc_mean = rowMeans(cbind(ecoli_conc_1, ecoli_conc_2, ecoli_conc_3), na.rm = TRUE)
  ) %>%
  select(id_faeces, ecoli_conc_mean, water_content_0dpi, ph) %>%
  rename(ph_0dpi = ph, ecoli_conc_mean_0dpi = ecoli_conc_mean)

# Save processed faeces data (file 1_2)
write.csv(faeces_1_2, "data/processed/faeces_1_2_processed.csv", row.names = FALSE)

# Process growth speed data (file 1_1)
growth_speed_1_1 <- read.csv("data/raw/growth_speed_1_1.csv") %>%
  mutate(date = as.Date(date)) %>%
  group_by(id_treatment) %>%
  mutate(
    first_date = min(date),
    dpi = as.numeric(date - first_date)
  ) %>%
  ungroup() %>%
  filter(dpi %in% c(7, 14)) %>%
  select(id_treatment, dpi, area_size, contamination_area, growth_description) %>%
  group_by(id_treatment, dpi) %>%
  summarise(
    area_size = mean(area_size, na.rm = TRUE),
    contamination_area = mean(contamination_area, na.rm = TRUE),
    growth_description = first(growth_description),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = dpi,
    values_from = c(area_size, contamination_area, growth_description),
    names_sep = "_"
  ) %>%
  rename_with(~ paste0(.x, "dpi"), matches("area_size_|contamination_area_|growth_description_")) %>%
  select(id_treatment, area_size_7dpi, area_size_14dpi, contamination_area_7dpi, contamination_area_14dpi,
         growth_description_7dpi, growth_description_14dpi)

# Save processed growth speed data (file 1_1)
write.csv(growth_speed_1_1, "data/processed/growth_speed_1_1_processed.csv", row.names = FALSE)

# Process growth speed data (file 1_2)
growth_speed_1_2 <- read.csv("data/raw/growth_speed_1_2.csv") %>%
  mutate(date = as.Date(date)) %>%
  group_by(id_treatment) %>%
  mutate(
    first_date = min(date),
    dpi = as.numeric(date - first_date)
  ) %>%
  ungroup() %>%
  filter(dpi %in% c(7, 14)) %>%
  select(id_treatment, dpi, area_size, contamination_area, growth_description) %>%
  group_by(id_treatment, dpi) %>%
  summarise(
    area_size = mean(area_size, na.rm = TRUE),
    contamination_area = mean(contamination_area, na.rm = TRUE),
    growth_description = first(growth_description),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = dpi,
    values_from = c(area_size, contamination_area, growth_description),
    names_sep = "_"
  ) %>%
  rename_with(~ paste0(.x, "dpi"), matches("area_size_|contamination_area_|growth_description_")) %>%
  select(id_treatment, area_size_7dpi, area_size_14dpi, contamination_area_7dpi, contamination_area_14dpi,
         growth_description_7dpi, growth_description_14dpi)

# Save processed growth speed data (file 1_2)
write.csv(growth_speed_1_2, "data/processed/growth_speed_1_2_processed.csv", row.names = FALSE)

# ============================================
# JOINING SECTION
# ============================================

# Read experiment tables
experiment_1_1 <- read.csv("data/raw/experiment_1_1.csv")
experiment_1_2 <- read.csv("data/raw/experiment_1_2.csv")

# Join experiment 1_1 with processed data
experiment_1_1_joined <- experiment_1_1 %>%
  # Join with growth speed data
  left_join(growth_speed_1_1, by = "id_treatment") %>%
  # Join with bacteria data
  left_join(bacteria_1_1, by = "id_treatment") %>%
  # Join with faeces data
  left_join(faeces_1_1, by = "id_faeces") %>%
  # Join with inoculum data
  left_join(
    read.csv("data/raw/inoculum_1_1.csv") %>%
      select(id_inoc, species, production_date),
    by = "id_inoc"
  )

# Join experiment 1_2 with processed data
experiment_1_2_joined <- experiment_1_2 %>%
  # Join with growth speed data
  left_join(growth_speed_1_2, by = "id_treatment") %>%
  # Join with bacteria data
  left_join(bacteria_1_2, by = "id_treatment") %>%
  # Join with faeces data
  left_join(faeces_1_2, by = "id_faeces") %>%
  # Join with inoculum data
  left_join(
    read.csv("data/raw/inoculum_1_2.csv") %>%
      select(id_inoc, species, production_date),
    by = "id_inoc"
  )

# ============================================
# SPECIES FILTERING SECTION
# ============================================

# Define species to keep
selected_species <- c(
  "F35 Sordaria",
  "G. lucidum", 
  "P. ostreatus",
  "P. ostreatus columbinus",
  "P. ostreatus v. Floridae",
  "F40",
  "F15 Faecal isolate 1",
  "F31 Mucor spp I3",
  "T. harzianum CBS245.93",
  "T. harzianum T22",
  "T. koningii",
  "coprinus comata",
  "ctrl"  # Keep control samples
)

# Filter experiment 1_1 data and add growth status column
experiment_1_1_joined_filtered <- experiment_1_1_joined %>%
  filter(species %in% selected_species) %>%
  mutate(
    growth_status_14dpi = case_when(
      # No growth if growth area < 15
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
    # Calculate percent weight change from 0 DPI to 14 DPI
    weight_percent_change = case_when(
      !is.na(weight_0dpi) & !is.na(weight_14dpi) & weight_0dpi > 0 ~ ((weight_14dpi - weight_0dpi) / weight_0dpi) * 100,
      TRUE ~ NA_real_
    )
  )

# Filter experiment 1_2 data and add growth status column
experiment_1_2_joined_filtered <- experiment_1_2_joined %>%
  filter(species %in% selected_species) %>%
  mutate(
    growth_status_14dpi = case_when(
      # No growth if growth area < 15
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
    # Calculate percent weight change from 0 DPI to 14 DPI
    weight_percent_change = case_when(
      !is.na(weight_0dpi) & !is.na(weight_14dpi) & weight_0dpi > 0 ~ ((weight_14dpi - weight_0dpi) / weight_0dpi) * 100,
      TRUE ~ NA_real_
    )
  )

# Save the original filtered joined data (for growth success analysis)
write.csv(experiment_1_1_joined_filtered, "data/processed/experiment_1_1_joined.csv", row.names = FALSE)
write.csv(experiment_1_2_joined_filtered, "data/processed/experiment_1_2_joined.csv", row.names = FALSE)

# ============================================
# CREATE SPECIALIZED FILTERED DATASETS
# ============================================

# Create filtered datasets for pH, weight change, and E.coli analysis
# Keep only:
# - Controls: "No growth, no contamination" and "Growth, contaminated" 
# - Fungal species: "Growth, no contamination" and "Growth, contaminated"

# Filter experiment 1_1 for pH/weight/ecoli analyses
experiment_1_1_ph_weight_ecoli <- experiment_1_1_joined_filtered %>%
  filter(
    # Keep controls with no growth/no contamination OR growth/contamination
    (species == "ctrl" & growth_status_14dpi %in% c("No growth, no contamination", "Growth, contaminated")) |
    # Keep fungal species with growth (contaminated or not)
    (species != "ctrl" & growth_status_14dpi %in% c("Growth, no contamination", "Growth, contaminated"))
  )

# Filter experiment 1_2 for pH/weight/ecoli analyses  
experiment_1_2_ph_weight_ecoli <- experiment_1_2_joined_filtered %>%
  filter(
    # Keep controls with no growth/no contamination OR growth/contamination
    (species == "ctrl" & growth_status_14dpi %in% c("No growth, no contamination", "Growth, contaminated")) |
    # Keep fungal species with growth (contaminated or not)
    (species != "ctrl" & growth_status_14dpi %in% c("Growth, no contamination", "Growth, contaminated"))
  )

# Save the specialized filtered datasets
write.csv(experiment_1_1_ph_weight_ecoli, "data/processed/experiment_1_1_ph_weight_ecoli.csv", row.names = FALSE)
write.csv(experiment_1_2_ph_weight_ecoli, "data/processed/experiment_1_2_ph_weight_ecoli.csv", row.names = FALSE)

# Print summary of filtering
cat("\n=== FILTERING SUMMARY ===\n")
cat("Original experiment 1_1 rows:", nrow(experiment_1_1_joined_filtered), "\n")
cat("pH/weight/ecoli experiment 1_1 rows:", nrow(experiment_1_1_ph_weight_ecoli), "\n")
cat("Original experiment 1_2 rows:", nrow(experiment_1_2_joined_filtered), "\n") 
cat("pH/weight/ecoli experiment 1_2 rows:", nrow(experiment_1_2_ph_weight_ecoli), "\n")

cat("\nExperiment 1_1 - Growth status distribution (pH/weight/ecoli dataset):\n")
print(table(experiment_1_1_ph_weight_ecoli$growth_status_14dpi, experiment_1_1_ph_weight_ecoli$species))

cat("\nExperiment 1_2 - Growth status distribution (pH/weight/ecoli dataset):\n")
print(table(experiment_1_2_ph_weight_ecoli$growth_status_14dpi, experiment_1_2_ph_weight_ecoli$species))
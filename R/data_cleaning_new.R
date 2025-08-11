library(tidyverse)
library(lubridate)

# Read raw data files
bacteria_raw <- read_csv("data/raw/bacteria_1_1.csv")
experiment_raw <- read_csv("data/raw/experiment_1_1.csv")
faeces_raw <- read_csv("data/raw/faeces_1_1.csv")
growth_speed_raw <- read_csv("data/raw/growth_speed_1_1.csv")
inoculum_raw <- read_csv("data/raw/inoculum_1_1.csv")

# Clean bacteria_1_1.csv
bacteria_clean <- bacteria_raw %>%
  mutate(
    # Convert to proper data types
    date = as_date(date),
    sample_weight = as.numeric(sample_weight),
    dilution_ecoli = as.numeric(dilution_ecoli),
    ecoli_counted = as.numeric(ecoli_counted),
    # Calculate E. coli concentration
    ecoli_conc = ecoli_counted * dilution_ecoli / sample_weight
  ) %>%
  # Select only required columns
  select(id_bact, id_treatment, date, ecoli_conc)

# Clean faeces_1_1.csv
faeces_clean <- faeces_raw %>%
  mutate(
    # Convert to proper data types
    ph = as.numeric(ph),
    water_content = as.numeric(water_content),
    sample_weight_1 = as.numeric(sample_weight_1),
    sample_weight_2 = as.numeric(sample_weight_2),
    sample_weight_3 = as.numeric(sample_weight_3),
    dilution_factor_ecoli = as.numeric(dilution_factor_ecoli),
    e_coli_counted_1 = as.numeric(e_coli_counted_1),
    e_coli_counted_2 = as.numeric(e_coli_counted_2),
    e_coli_counted_3 = as.numeric(e_coli_counted_3),
    # Calculate E. coli concentrations for each sample
    ecoli_conc_1 = e_coli_counted_1 * dilution_factor_ecoli / sample_weight_1,
    ecoli_conc_2 = e_coli_counted_2 * dilution_factor_ecoli / sample_weight_2,
    ecoli_conc_3 = e_coli_counted_3 * dilution_factor_ecoli / sample_weight_3
  ) %>%
  rowwise() %>%
  mutate(
    # Calculate mean and SD of E. coli concentrations
    ecoli_conc_mean = mean(c(ecoli_conc_1, ecoli_conc_2, ecoli_conc_3), na.rm = TRUE),
    ecoli_conc_sd = sd(c(ecoli_conc_1, ecoli_conc_2, ecoli_conc_3), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  # Select only required columns
  select(id_faeces, ph, water_content, ecoli_conc_1, ecoli_conc_2, ecoli_conc_3, 
         ecoli_conc_mean, ecoli_conc_sd)

# Clean growth_speed_1_1.csv
growth_speed_clean <- growth_speed_raw %>%
  mutate(
    # Convert to proper data types
    date = as_date(date),
    area_size = as.numeric(area_size)
  ) %>%
  # Remove duplicates by taking the mean if there are multiple measurements
  group_by(id_treatment, date) %>%
  summarise(
    area_size = mean(area_size, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Calculate days post inoculation (dpi) for each treatment
  group_by(id_treatment) %>%
  mutate(
    min_date = min(date),
    dpi = as.numeric(date - min_date)
  ) %>%
  ungroup() %>%
  # Pivot to wide format for area_size
  select(id_treatment, dpi, area_size) %>%
  pivot_wider(
    names_from = dpi,
    values_from = area_size,
    names_glue = "area_size_{dpi}dpi",
    values_fn = mean  # Handle any remaining duplicates
  )

# Calculate growth columns separately to avoid issues
# Get column names for area_size columns (excluding 0dpi)
area_cols <- names(growth_speed_clean)[grepl("area_size_[0-9]+dpi", names(growth_speed_clean)) & 
                                        !grepl("area_size_0dpi", names(growth_speed_clean))]

# Calculate growth for each column if area_size_0dpi exists
if("area_size_0dpi" %in% names(growth_speed_clean)) {
  for(col in area_cols) {
    growth_col <- sub("area_size_", "growth_", col)
    growth_speed_clean[[growth_col]] <- growth_speed_clean[[col]] - growth_speed_clean[["area_size_0dpi"]]
  }
}

# Select final columns
growth_speed_clean <- growth_speed_clean %>%
  select(id_treatment, starts_with("area_size_"), starts_with("growth_"))

# Clean inoculum_1_1.csv
inoculum_clean <- inoculum_raw %>%
  mutate(
    # Clean species column - rename all entries containing "ctrl" to "ctrl"
    species = case_when(
      str_detect(tolower(species), "ctrl") ~ "ctrl",
      TRUE ~ species
    )
  ) %>%
  # Select only required columns
  select(id_inoc, species)

# Clean experiment_1_1.csv
experiment_clean <- experiment_raw %>%
  mutate(
    # Convert to proper data types
    starting_date = as_date(starting_date),
    weight_0dpi = as.numeric(weight_0dpi),
    weight_14dpi = as.numeric(weight_14dpi),
    water_content_14dpi = case_when(
      water_content_14dpi == "x" ~ NA_real_,
      TRUE ~ as.numeric(water_content_14dpi)
    ),
    ph_14dpi = as.numeric(ph_14dpi)
  )

# Join bacteria data to experiment table
# First, get E. coli concentration for each treatment at each date
bacteria_summary <- bacteria_clean %>%
  mutate(
    # Calculate dpi based on experiment starting date
    # We'll need to join with experiment first to get starting_date
    temp_id = id_treatment
  ) %>%
  left_join(experiment_clean %>% select(id_treatment, starting_date), 
            by = c("temp_id" = "id_treatment")) %>%
  mutate(
    dpi = as.numeric(date - starting_date)
  ) %>%
  group_by(id_treatment, dpi) %>%
  summarise(
    ecoli_conc_mean = mean(ecoli_conc, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = dpi,
    values_from = ecoli_conc_mean,
    names_glue = "ecoli_conc_{dpi}dpi"
  )

# Join all tables to experiment table
experiment_final <- experiment_clean %>%
  # Join inoculum data
  left_join(inoculum_clean, by = "id_inoc") %>%
  # Join faeces data
  left_join(faeces_clean, by = "id_faeces") %>%
  # Join growth data
  left_join(growth_speed_clean, by = "id_treatment") %>%
  # Join bacteria summary data
  left_join(bacteria_summary, by = "id_treatment")

# Save cleaned data
write_csv(bacteria_clean, "data/processed/bacteria_cleaned.csv")
write_csv(faeces_clean, "data/processed/faeces_cleaned.csv")
write_csv(growth_speed_clean, "data/processed/growth_speed_cleaned.csv")
write_csv(inoculum_clean, "data/processed/inoculum_cleaned.csv")
write_csv(experiment_final, "data/processed/experiment_final.csv")

# Also save individual cleaned tables
write_csv(experiment_clean, "data/processed/experiment_cleaned.csv")

cat("Data cleaning completed successfully!\n")
cat("Files saved to data/processed/ folder\n")
cat("\nFinal experiment table includes:\n")
cat("- Original experiment data\n")
cat("- Inoculum data (species information)\n")
cat("- Faeces data (pH, water content, E. coli concentrations)\n")
cat("- Growth data (area size and growth at different dpi)\n")
cat("- Bacteria data (E. coli concentrations at different dpi)\n")
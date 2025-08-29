# Load required packages
library(tidyverse)
library(lubridate)
library(here)

# Read raw data files for 1_1
bacteria_1_1 <- read_csv(here("data", "raw", "bacteria_1_1.csv"), show_col_types = FALSE)
experiment_1_1 <- read_csv(here("data", "raw", "experiment_1_1.csv"), show_col_types = FALSE)
faeces_1_1 <- read_csv(here("data", "raw", "faeces_1_1.csv"), show_col_types = FALSE)
growth_speed_1_1 <- read_csv(here("data", "raw", "growth_speed_1_1.csv"), show_col_types = FALSE)
inoculum_1_1 <- read_csv(here("data", "raw", "inoculum_1_1.csv"), show_col_types = FALSE)

# Read raw data files for 1_2 with error handling
if(file.exists(here("data", "raw", "bacteria_1_2.csv"))) {
  bacteria_1_2 <- read_csv(here("data", "raw", "bacteria_1_2.csv"), show_col_types = FALSE)
  experiment_1_2 <- read_csv(here("data", "raw", "experiment_1_2.csv"), show_col_types = FALSE)
  faeces_1_2 <- read_csv(here("data", "raw", "faeces_1_2.csv"), show_col_types = FALSE)
  growth_speed_1_2 <- read_csv(here("data", "raw", "growth_speed_1_2.csv"), show_col_types = FALSE)
  inoculum_1_2 <- read_csv(here("data", "raw", "inoculum_1_2.csv"), show_col_types = FALSE)
} else {
  bacteria_1_2 <- tibble()
  experiment_1_2 <- tibble()
  faeces_1_2 <- tibble()
  growth_speed_1_2 <- tibble()
  inoculum_1_2 <- tibble()
}

# Add experiment identifier and ensure type compatibility
# Convert all columns to character first to avoid type conflicts during bind_rows
bacteria_1_1 <- bacteria_1_1 %>% 
  mutate(across(everything(), as.character)) %>%
  mutate(experiment = "1_1")

if(nrow(bacteria_1_2) > 0) {
  bacteria_1_2 <- bacteria_1_2 %>% 
    mutate(across(everything(), as.character)) %>%
    mutate(experiment = "1_2")
}

experiment_1_1 <- experiment_1_1 %>% 
  mutate(across(everything(), as.character)) %>%
  mutate(experiment = "1_1")

if(nrow(experiment_1_2) > 0) {
  experiment_1_2 <- experiment_1_2 %>% 
    mutate(across(everything(), as.character)) %>%
    mutate(experiment = "1_2")
}

faeces_1_1 <- faeces_1_1 %>% 
  mutate(across(everything(), as.character)) %>%
  mutate(experiment = "1_1")

if(nrow(faeces_1_2) > 0) {
  faeces_1_2 <- faeces_1_2 %>% 
    mutate(across(everything(), as.character)) %>%
    mutate(experiment = "1_2")
}

growth_speed_1_1 <- growth_speed_1_1 %>% 
  mutate(across(everything(), as.character)) %>%
  mutate(experiment = "1_1")

if(nrow(growth_speed_1_2) > 0) {
  growth_speed_1_2 <- growth_speed_1_2 %>% 
    mutate(across(everything(), as.character)) %>%
    mutate(experiment = "1_2")
}

inoculum_1_1 <- inoculum_1_1 %>% 
  mutate(across(everything(), as.character)) %>%
  mutate(experiment = "1_1")

if(nrow(inoculum_1_2) > 0) {
  inoculum_1_2 <- inoculum_1_2 %>% 
    mutate(across(everything(), as.character)) %>%
    mutate(experiment = "1_2")
}

# Combine 1_1 and 1_2 data
bacteria_raw <- bind_rows(bacteria_1_1, bacteria_1_2)
experiment_raw <- bind_rows(experiment_1_1, experiment_1_2)
faeces_raw <- bind_rows(faeces_1_1, faeces_1_2)
growth_speed_raw <- bind_rows(growth_speed_1_1, growth_speed_1_2)
inoculum_raw <- bind_rows(inoculum_1_1, inoculum_1_2)

# Clean bacteria data
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
  select(id_bact, id_treatment, date, ecoli_conc, experiment)

# Clean faeces data
faeces_clean <- faeces_raw %>%
  mutate(
    # Convert to proper data types
    ph = as.numeric(ph),
    water_content = as.numeric(water_content_0dpi),
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
         ecoli_conc_mean, ecoli_conc_sd, experiment)

# Clean growth speed data
growth_speed_clean <- growth_speed_raw %>%
  mutate(
    # Convert to proper data types
    date = as_date(date),
    area_size = as.numeric(area_size)
  ) %>%
  # Remove duplicates by taking the mean if there are multiple measurements
  group_by(id_treatment, date, experiment) %>%
  summarise(
    area_size = mean(area_size, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Calculate days post inoculation (dpi) for each treatment
  group_by(id_treatment, experiment) %>%
  mutate(
    min_date = min(date),
    dpi = as.numeric(date - min_date)
  ) %>%
  ungroup() %>%
  # Pivot to wide format for area_size
  select(id_treatment, experiment, dpi, area_size) %>%
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
  select(id_treatment, experiment, starts_with("area_size_"), starts_with("growth_"))

# Clean inoculum data
inoculum_clean <- inoculum_raw %>%
  mutate(
    # Clean species column - rename all entries containing "ctrl" to "ctrl"
    species = case_when(
      str_detect(tolower(species), "ctrl") ~ "ctrl",
      TRUE ~ species
    )
  ) %>%
  # Select only required columns
  select(id_inoc, species, experiment)

# Clean experiment data
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
  left_join(experiment_clean %>% select(id_treatment, starting_date, experiment), 
            by = c("temp_id" = "id_treatment", "experiment")) %>%
  mutate(
    dpi = as.numeric(date - starting_date)
  ) %>%
  group_by(id_treatment, experiment, dpi) %>%
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
  left_join(inoculum_clean, by = c("id_inoc", "experiment")) %>%
  # Join faeces data
  left_join(faeces_clean, by = c("id_faeces", "experiment")) %>%
  # Join growth data
  left_join(growth_speed_clean, by = c("id_treatment", "experiment")) %>%
  # Join bacteria summary data
  left_join(bacteria_summary, by = c("id_treatment", "experiment")) %>%
  # Add ph_0dpi from faeces table (renaming ph to ph_0dpi)
  rename(ph_0dpi = ph) %>%
  # Calculate dry weights
  mutate(
    # Calculate dry weight for 0 dpi using water_content from faeces table
    dry_weight_0dpi = weight_0dpi * (1 - water_content),
    # Calculate dry weight for 14 dpi using water_content_14dpi
    dry_weight_14dpi = weight_14dpi * (1 - water_content_14dpi),
    # Calculate dry weight change
    dry_weight_change = dry_weight_14dpi - dry_weight_0dpi,
    # Calculate dry weight percent change
    dry_weight_percent_change = (dry_weight_change / dry_weight_0dpi) * 100
  )

# Create processed directory if it doesn't exist
dir.create(here("data", "processed"), recursive = TRUE, showWarnings = FALSE)

# Save cleaned data
write_csv(bacteria_clean, here("data", "processed", "bacteria_cleaned.csv"))
write_csv(faeces_clean, here("data", "processed", "faeces_cleaned.csv"))
write_csv(growth_speed_clean, here("data", "processed", "growth_speed_cleaned.csv"))
write_csv(inoculum_clean, here("data", "processed", "inoculum_cleaned.csv"))
write_csv(experiment_final, here("data", "processed", "experiment_final.csv"))

# Also save individual cleaned tables
write_csv(experiment_clean, here("data", "processed", "experiment_cleaned.csv"))

cat("Data cleaning completed successfully!\n")
cat("Files saved to data/processed/ folder\n")
cat("\nFinal experiment table includes:\n")
cat("- Original experiment data\n")
cat("- Inoculum data (species information)\n")
cat("- Faeces data (pH, water content, E. coli concentrations)\n")
cat("- Growth data (area size and growth at different dpi)\n")
cat("- Bacteria data (E. coli concentrations at different dpi)\n")
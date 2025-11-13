# ============================================
# FUNGAL TREATMENT ANALYSIS - EXPERIMENT 1_2
# Created: 2025-11-11
# Purpose: Complete analysis pipeline for fungal faecal treatment experiment 1_2
# ============================================

# ============================================
# LOAD REQUIRED LIBRARIES
# ============================================
# Data manipulation and visualization
library(tidyverse)
library(ggplot2)
library(gridExtra)

# Statistical analysis
library(lme4)
library(emmeans)
library(performance)

# Table formatting
library(knitr)
library(kableExtra)

# Color palettes
library(RColorBrewer)
library(scales)
library(ggtext)

# ============================================
# DEFINE VISUALIZATION THEMES AND COLORS
# ============================================

# Define professional color palettes
experiment_colors <- c("Experiment 1_1" = "#2166AC", "Experiment 1_2" = "#B2182B")

# Treatment categories color scheme (colorblind-friendly)
treatment_colors <- c(
  "Control: No growth, no contamination" = "#000000",
  "Control: No growth, contaminated" = "#666666", 
  "Control: Growth, no contamination" = "#999999",
  "Control: Growth, contaminated" = "#CCCCCC",
  "No growth, no contamination" = "#E69F00",
  "No growth, contaminated" = "#56B4E9",
  "Growth, contaminated" = "#009E73",
  "Growth, no contamination" = "#F0E442"
)

# Species-specific colors for comparisons
species_colors <- c("P. ostreatus columbinus" = "#2166AC", "G. lucidum" = "#B2182B")

# Define publication theme
theme_publication <- function() {
  theme_minimal(base_size = 10) +
  theme(
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 9, color = "black"),
    axis.text.y = element_text(size = 9, lineheight = 0.8),
    plot.title = element_text(size = 12, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 10, hjust = 0, color = "gray30"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "grey90", size = 0.3),
    panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    plot.margin = margin(t = 10, r = 10, b = 10, l = 10, unit = "pt"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9)
  )
}

# ============================================
# DATA PROCESSING FUNCTIONS
# ============================================

# Function to safely read CSV files with error handling
read_csv_safe <- function(file_path) {
  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }
  read.csv(file_path, stringsAsFactors = FALSE)
}

# Function to calculate E. coli concentrations
calculate_ecoli_conc <- function(counted, dilution, weight) {
  ifelse(!is.na(counted) & !is.na(dilution) & !is.na(weight) & weight > 0,
         counted * dilution / weight,
         NA_real_)
}

# Function to calculate dry weights
calculate_dry_weight <- function(wet_weight, water_content) {
  # Ensure water_content is in decimal form (0-1)
  if (any(water_content > 1, na.rm = TRUE)) {
    water_content <- water_content / 100
  }
  
  ifelse(!is.na(wet_weight) & !is.na(water_content) & water_content < 1,
         wet_weight * (1 - water_content),
         NA_real_)
}

# ============================================
# PROCESS RAW DATA FILES
# ============================================

cat("=== PROCESSING RAW DATA FILES ===\n")

# Process bacteria data
bacteria_1_2 <- read_csv_safe("data/raw/bacteria_1_2.csv") %>%
  mutate(
    ecoli_conc = calculate_ecoli_conc(ecoli_counted, dilution_ecoli, sample_weight)
  ) %>%
  select(id_treatment, ecoli_conc)

write.csv(bacteria_1_2, "data/processed/bacteria_1_2_processed.csv", row.names = FALSE)
cat("✓ Bacteria data processed\n")

# Process faeces data
faeces_1_2 <- read_csv_safe("data/raw/faeces_1_2.csv") %>%
  mutate(
    # Calculate E. coli concentrations for each replicate
    ecoli_conc_1 = calculate_ecoli_conc(e_coli_counted_1, dilution_factor_ecoli, sample_weight_1),
    ecoli_conc_2 = calculate_ecoli_conc(e_coli_counted_2, dilution_factor_ecoli, sample_weight_2),
    ecoli_conc_3 = calculate_ecoli_conc(e_coli_counted_3, dilution_factor_ecoli, sample_weight_3),
    
    # Calculate mean E. coli concentration across replicates
    ecoli_conc_mean = rowMeans(
      cbind(ecoli_conc_1, ecoli_conc_2, ecoli_conc_3), 
      na.rm = TRUE
    )
  ) %>%
  select(id_faeces, ecoli_conc_mean, water_content_0dpi, ph) %>%
  rename(
    ph_0dpi = ph, 
    ecoli_conc_mean_0dpi = ecoli_conc_mean
  )

write.csv(faeces_1_2, "data/processed/faeces_1_2_processed.csv", row.names = FALSE)
cat("✓ Faeces data processed\n")

# Process growth speed data
growth_speed_1_2 <- read_csv_safe("data/raw/growth_speed_1_2.csv") %>%
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
  # Pivot to wide format for easier joining
  pivot_wider(
    names_from = dpi,
    values_from = c(area_size, contamination_area, growth_description),
    names_sep = "_"
  ) %>%
  # Rename columns with 'dpi' suffix
  rename_with(
    ~ paste0(.x, "dpi"), 
    matches("area_size_|contamination_area_|growth_description_")
  )

write.csv(growth_speed_1_2, "data/processed/growth_speed_1_2_processed.csv", row.names = FALSE)
cat("✓ Growth speed data processed\n")

# ============================================
# JOIN ALL DATASETS
# ============================================

cat("\n=== JOINING DATASETS ===\n")

# Read main experiment table and inoculum data
experiment_1_2 <- read_csv_safe("data/raw/experiment_1_2.csv")
inoculum_1_2 <- read_csv_safe("data/raw/inoculum_1_2.csv") %>%
  select(id_inoc, species, production_date)

# Join all data together
experiment_1_2_joined <- experiment_1_2 %>%
  left_join(growth_speed_1_2, by = "id_treatment") %>%
  left_join(bacteria_1_2, by = "id_treatment") %>%
  left_join(faeces_1_2, by = "id_faeces") %>%
  left_join(inoculum_1_2, by = "id_inoc")

cat("✓ All datasets joined successfully\n")

# ============================================
# FILTER BY SELECTED SPECIES
# ============================================

# Define species of interest based on experimental design
selected_species <- c(
  # Saprophytic and ligninolytic species
  "F35 Sordaria",
  "G. lucidum", 
  "P. ostreatus columbinus",
  "P. ostreatus",
  "P. ostreatus v. Floridae",
  "P. ostreatus v.F",
  "Coprinus comata",
  
  # Faecal isolates
  "F15 Faecal isolate 1",
  "F31 Mucor spp I3",
  "F40",
  
  # Trichoderma strains
  "T. harzianum CBS245.93",
  "T. harzianum T22",
  "T. koningii",
  
  # Control
  "ctrl"
)

# Filter for selected species and add calculated columns
experiment_1_2_filtered <- experiment_1_2_joined %>%
  filter(species %in% selected_species) %>%
  mutate(
    # Classify growth status at 14 DPI based on area size and contamination
    growth_status_14dpi = case_when(
      # No growth if area < 15 mm²
      is.na(area_size_14dpi) | area_size_14dpi < 15 ~ case_when(
        is.na(contamination_area_14dpi) | contamination_area_14dpi < 10 ~ "No growth, no contamination",
        contamination_area_14dpi >= 10 ~ "No growth, contaminated"
      ),
      # Growth present (area >= 15 mm²)
      area_size_14dpi >= 15 ~ case_when(
        is.na(contamination_area_14dpi) | contamination_area_14dpi < area_size_14dpi ~ "Growth, no contamination",
        contamination_area_14dpi >= area_size_14dpi ~ "Growth, contaminated"
      ),
      TRUE ~ "Other"
    ),
    
    # Calculate dry weights
    dry_weight_0dpi = calculate_dry_weight(weight_0dpi, water_content_0dpi),
    dry_weight_14dpi = calculate_dry_weight(weight_14dpi, water_content_14dpi),
    
    # Calculate weight changes
    dry_weight_change = dry_weight_14dpi - dry_weight_0dpi,
    dry_weight_percent_change = ifelse(
      !is.na(dry_weight_0dpi) & dry_weight_0dpi > 0,
      (dry_weight_change / dry_weight_0dpi) * 100,
      NA_real_
    ),
    weight_percent_change = ifelse(
      !is.na(weight_0dpi) & weight_0dpi > 0,
      ((weight_14dpi - weight_0dpi) / weight_0dpi) * 100,
      NA_real_
    ),
    
    # Calculate E. coli log reduction
    log_ecoli_14dpi = ifelse(ecoli_conc > 0, log10(ecoli_conc), NA_real_),
    log_ecoli_0dpi = ifelse(ecoli_conc_mean_0dpi > 0, log10(ecoli_conc_mean_0dpi), NA_real_),
    ecoli_log_reduction = log_ecoli_0dpi - log_ecoli_14dpi
  )

# Save the full filtered dataset
write.csv(experiment_1_2_filtered, "data/processed/experiment_1_2_joined.csv", row.names = FALSE)
cat("\n✓ Filtered dataset saved\n")

# ============================================
# CREATE SPECIALIZED ANALYSIS DATASET
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
cat("✓ Analysis dataset created\n")

# ============================================
# DATA QUALITY SUMMARY
# ============================================

cat("\n=== DATA PROCESSING SUMMARY ===\n")
cat("Total samples after species filtering:", nrow(experiment_1_2_filtered), "\n")
cat("Samples in analysis dataset:", nrow(experiment_1_2_analysis), "\n")

cat("\nSamples by growth status (analysis dataset):\n")
print(table(experiment_1_2_analysis$growth_status_14dpi))

cat("\nSamples by species (analysis dataset):\n")
print(table(experiment_1_2_analysis$species))

# Check missing data
cat("\n=== MISSING DATA SUMMARY ===\n")
cat("Samples with weight_14dpi:", sum(!is.na(experiment_1_2_analysis$weight_14dpi)), "\n")
cat("Samples with dry_weight_14dpi:", sum(!is.na(experiment_1_2_analysis$dry_weight_14dpi)), "\n")
cat("Samples with pH_14dpi:", sum(!is.na(experiment_1_2_analysis$ph_14dpi)), "\n")
cat("Samples with E. coli data at 14 DPI:", sum(!is.na(experiment_1_2_analysis$ecoli_conc)), "\n")

missing_dry_weight <- sum(
  !is.na(experiment_1_2_analysis$weight_14dpi) & 
  is.na(experiment_1_2_analysis$dry_weight_14dpi)
)
cat("Missing dry weight despite having wet weight:", missing_dry_weight, "\n")

# ============================================
# GROWTH SUCCESS ANALYSIS
# ============================================

cat("\n=== GROWTH SUCCESS ANALYSIS ===\n")

# Prepare growth success data for visualization
growth_success_data <- experiment_1_2_filtered %>%
  select(id_treatment, species, growth_description_7dpi, growth_description_14dpi) %>%
  pivot_longer(
    cols = c(growth_description_7dpi, growth_description_14dpi),
    names_to = "time_point",
    values_to = "growth_description"
  ) %>%
  mutate(
    time_point = case_when(
      time_point == "growth_description_7dpi" ~ "7 DPI",
      time_point == "growth_description_14dpi" ~ "14 DPI"
    ),
    growth_description = as.factor(growth_description)
  ) %>%
  filter(!is.na(growth_description))

# Calculate success rates by species and time point
success_summary <- growth_success_data %>%
  group_by(species, time_point) %>%
  summarise(
    n_total = n(),
    n_success = sum(growth_description %in% c(4, 5)),
    success_rate = (n_success / n_total) * 100,
    .groups = "drop"
  )

cat("\nGrowth success rates by species:\n")
print(success_summary %>% 
      filter(time_point == "14 DPI") %>%
      arrange(desc(success_rate)))

# ============================================
# GROWTH AREA ANALYSIS
# ============================================

cat("\n=== GROWTH AREA ANALYSIS ===\n")

# Prepare area data for analysis
area_data_long <- experiment_1_2_filtered %>%
  filter(!is.na(area_size_14dpi) & area_size_14dpi > 0) %>%
  select(id_treatment, species, area_size_7dpi, area_size_14dpi) %>%
  pivot_longer(
    cols = c(area_size_7dpi, area_size_14dpi),
    names_to = "time_point",
    values_to = "area_size"
  ) %>%
  mutate(
    time_point = case_when(
      time_point == "area_size_7dpi" ~ "7 DPI",
      time_point == "area_size_14dpi" ~ "14 DPI"
    ),
    log_area = log10(area_size + 1)
  ) %>%
  filter(!is.na(area_size) & area_size > 0)

# Summary statistics for growth areas
area_summary <- area_data_long %>%
  group_by(species, time_point) %>%
  summarise(
    n = n(),
    mean_area = mean(area_size, na.rm = TRUE),
    sd_area = sd(area_size, na.rm = TRUE),
    median_area = median(area_size, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nGrowth area summary at 14 DPI:\n")
print(area_summary %>% 
      filter(time_point == "14 DPI") %>%
      arrange(desc(mean_area)))

# ============================================
# WEIGHT CHANGE ANALYSIS
# ============================================

cat("\n=== WEIGHT CHANGE ANALYSIS ===\n")

# Analyze weight changes by treatment
weight_summary <- experiment_1_2_analysis %>%
  filter(!is.na(weight_percent_change)) %>%
  group_by(species) %>%
  summarise(
    n = n(),
    mean_weight_change = mean(weight_percent_change, na.rm = TRUE),
    sd_weight_change = sd(weight_percent_change, na.rm = TRUE),
    mean_dry_weight_change = mean(dry_weight_percent_change, na.rm = TRUE),
    sd_dry_weight_change = sd(dry_weight_percent_change, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nWeight change summary by species:\n")
print(weight_summary %>% arrange(mean_weight_change))

# ============================================
# pH CHANGE ANALYSIS
# ============================================

cat("\n=== pH CHANGE ANALYSIS ===\n")

# Calculate pH changes
ph_summary <- experiment_1_2_analysis %>%
  filter(!is.na(ph_0dpi) & !is.na(ph_14dpi)) %>%
  mutate(ph_change = ph_14dpi - ph_0dpi) %>%
  group_by(species) %>%
  summarise(
    n = n(),
    mean_ph_initial = mean(ph_0dpi, na.rm = TRUE),
    mean_ph_final = mean(ph_14dpi, na.rm = TRUE),
    mean_ph_change = mean(ph_change, na.rm = TRUE),
    sd_ph_change = sd(ph_change, na.rm = TRUE),
    .groups = "drop"
  )

cat("\npH change summary by species:\n")
print(ph_summary %>% arrange(desc(mean_ph_change)))

# ============================================
# E. COLI REDUCTION ANALYSIS
# ============================================

cat("\n=== E. COLI REDUCTION ANALYSIS ===\n")

# Analyze E. coli log reductions
ecoli_summary <- experiment_1_2_analysis %>%
  filter(!is.na(ecoli_log_reduction)) %>%
  group_by(species) %>%
  summarise(
    n = n(),
    mean_log_reduction = mean(ecoli_log_reduction, na.rm = TRUE),
    sd_log_reduction = sd(ecoli_log_reduction, na.rm = TRUE),
    median_log_reduction = median(ecoli_log_reduction, na.rm = TRUE),
    max_log_reduction = max(ecoli_log_reduction, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nE. coli log reduction summary by species:\n")
print(ecoli_summary %>% arrange(desc(mean_log_reduction)))

# ============================================
# STATISTICAL ANALYSIS
# ============================================

cat("\n=== STATISTICAL ANALYSIS ===\n")

# Weight change analysis - comparing treatments to control
if (length(unique(experiment_1_2_analysis$species)) > 1) {
  cat("\nTesting weight changes between species and control...\n")
  
  # Prepare data for analysis
  weight_data <- experiment_1_2_analysis %>%
    filter(!is.na(weight_percent_change)) %>%
    mutate(
      is_control = ifelse(species == "ctrl", "Control", "Treatment"),
      species_factor = factor(species)
    )
  
  # Kruskal-Wallis test
  kw_test <- kruskal.test(weight_percent_change ~ species_factor, data = weight_data)
  cat("Kruskal-Wallis test p-value:", format(kw_test$p.value, digits = 3), "\n")
  
  # Post-hoc pairwise comparisons if significant
  if (kw_test$p.value < 0.05) {
    cat("Performing pairwise comparisons with control...\n")
    
    control_data <- weight_data %>% filter(species == "ctrl")
    
    pairwise_results <- weight_data %>%
      filter(species != "ctrl") %>%
      group_by(species) %>%
      summarise(
        n = n(),
        p_value = wilcox.test(
          weight_percent_change,
          control_data$weight_percent_change
        )$p.value,
        .groups = "drop"
      ) %>%
      mutate(p_adjusted = p.adjust(p_value, method = "bonferroni"))
    
    print(pairwise_results)
  }
}

# ============================================
# CREATE VISUALIZATIONS
# ============================================

cat("\n=== CREATING VISUALIZATIONS ===\n")

# 1. Growth Success Heatmap
growth_heatmap <- growth_success_data %>%
  count(species, time_point, growth_description) %>%
  group_by(species, time_point) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot(aes(x = time_point, y = species, fill = growth_description)) +
  geom_tile(aes(alpha = prop), color = "white") +
  scale_fill_manual(
    values = c("0" = "#d73027", "1" = "#fc8d59", "2" = "#fee090", 
               "3" = "#e0f3f8", "4" = "#91bfdb", "5" = "#4575b4"),
    name = "Growth Score"
  ) +
  scale_alpha(range = c(0.3, 1), guide = FALSE) +
  labs(
    title = "Growth Success by Species and Time Point",
    subtitle = "0 = No growth, 5 = Full growth without contamination",
    x = "Time Point",
    y = "Species"
  ) +
  theme_publication() +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    axis.text.y = element_text(size = 8)
  )

# Save plot
ggsave("figures/growth_success_heatmap_exp1_2.png", 
       growth_heatmap, 
       width = 10, 
       height = 8, 
       dpi = 300)

# 2. Area Size Distribution Plot
area_plot <- area_data_long %>%
  filter(time_point == "14 DPI") %>%
  mutate(species = fct_reorder(species, area_size, median)) %>%
  ggplot(aes(x = area_size, y = species)) +
  geom_boxplot(fill = "darkgreen", alpha = 0.6, color = "darkgreen") +
  geom_point(alpha = 0.6, size = 1, color = "darkred", 
             position = position_jitter(height = 0.2)) +
  scale_x_log10(
    breaks = c(10, 100, 1000, 10000),
    labels = scales::comma
  ) +
  labs(
    title = "Fungal Growth Area Distribution at 14 DPI",
    subtitle = "Log scale; points represent individual measurements",
    x = "Area Size (mm², log scale)",
    y = "Species"
  ) +
  theme_publication()

# Save plot
ggsave("figures/area_distribution_exp1_2.png", 
       area_plot, 
       width = 10, 
       height = 8, 
       dpi = 300)

# 3. Weight Change Comparison Plot
weight_plot <- experiment_1_2_analysis %>%
  filter(!is.na(weight_percent_change)) %>%
  mutate(
    species = fct_reorder(species, weight_percent_change, median),
    treatment_type = ifelse(species == "ctrl", "Control", "Fungal Treatment")
  ) %>%
  ggplot(aes(x = weight_percent_change, y = species, fill = treatment_type)) +
  geom_boxplot(alpha = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_fill_manual(
    values = c("Control" = "gray50", "Fungal Treatment" = "#2166AC"),
    name = "Treatment Type"
  ) +
  labs(
    title = "Weight Change After 14 Days of Treatment",
    subtitle = "Negative values indicate weight loss (decomposition)",
    x = "Weight Change (%)",
    y = "Species"
  ) +
  theme_publication()

# Save plot
ggsave("figures/weight_change_exp1_2.png", 
       weight_plot, 
       width = 10, 
       height = 8, 
       dpi = 300)

# 4. pH Change Analysis Plot
ph_plot <- experiment_1_2_analysis %>%
  filter(!is.na(ph_0dpi) & !is.na(ph_14dpi)) %>%
  mutate(ph_change = ph_14dpi - ph_0dpi) %>%
  select(species, ph_0dpi, ph_14dpi) %>%
  pivot_longer(
    cols = c(ph_0dpi, ph_14dpi),
    names_to = "time_point",
    values_to = "ph"
  ) %>%
  mutate(
    time_point = factor(
      time_point, 
      levels = c("ph_0dpi", "ph_14dpi"),
      labels = c("0 DPI", "14 DPI")
    )
  ) %>%
  ggplot(aes(x = time_point, y = ph, group = species, color = species)) +
  geom_line(alpha = 0.3) +
  geom_boxplot(aes(group = interaction(species, time_point), fill = species), 
               alpha = 0.5, outlier.shape = NA) +
  facet_wrap(~ species, nrow = 2) +
  labs(
    title = "pH Changes During Treatment",
    subtitle = "Individual trajectories and distributions",
    x = "Time Point",
    y = "pH"
  ) +
  theme_publication() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Save plot
ggsave("figures/ph_changes_exp1_2.png", 
       ph_plot, 
       width = 12, 
       height = 8, 
       dpi = 300)

# 5. E. coli Reduction Plot
ecoli_plot <- experiment_1_2_analysis %>%
  filter(!is.na(ecoli_log_reduction)) %>%
  mutate(
    species = fct_reorder(species, ecoli_log_reduction, median),
    treatment_type = ifelse(species == "ctrl", "Control", "Fungal Treatment")
  ) %>%
  ggplot(aes(x = ecoli_log_reduction, y = species, fill = treatment_type)) +
  geom_boxplot(alpha = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.5) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "green", alpha = 0.5) +
  geom_vline(xintercept = 3, linetype = "dashed", color = "darkgreen", alpha = 0.5) +
  scale_fill_manual(
    values = c("Control" = "gray50", "Fungal Treatment" = "#B2182B"),
    name = "Treatment Type"
  ) +
  scale_x_continuous(breaks = seq(-2, 6, 1)) +
  labs(
    title = "E. coli Log Reduction After 14 Days",
    subtitle = "Positive values indicate bacterial reduction; lines at 1 and 3 log reduction",
    x = "Log₁₀ Reduction",
    y = "Species"
  ) +
  theme_publication()

# Save plot
ggsave("figures/ecoli_reduction_exp1_2.png", 
       ecoli_plot, 
       width = 10, 
       height = 8, 
       dpi = 300)

# 6. Faecal Characteristics vs Growth Success (for P. ostreatus and G. lucidum)
growth_faecal_data <- experiment_1_2_filtered %>%
  filter(species %in% c("P. ostreatus columbinus", "G. lucidum")) %>%
  filter(!is.na(area_size_14dpi)) %>%
  mutate(
    growth_success_binary = factor(
      ifelse(area_size_14dpi > 10, "1", "0"),
      levels = c("0", "1")
    ),
    log_ecoli_0dpi = log10(ecoli_conc_mean_0dpi + 1)
  )

if (nrow(growth_faecal_data) > 0) {
  # pH plot
  ph_growth_plot <- ggplot(growth_faecal_data, 
                          aes(x = growth_success_binary, y = ph_0dpi, fill = species)) +
    geom_boxplot(alpha = 0.7, position = position_dodge(width = 0.8)) +
    geom_point(aes(color = species), alpha = 0.6, size = 1.5, 
               position = position_jitterdodge(jitter.width = 0.2, dodge.width = 0.8)) +
    labs(
      title = "A) Initial pH vs Growth Success by Species",
      subtitle = "P. ostreatus vs G. lucidum comparison",
      x = "Growth Outcome",
      y = "pH at 0 DPI",
      fill = "Species",
      color = "Species"
    ) +
    theme_publication() +
    scale_fill_manual(values = species_colors) +
    scale_color_manual(values = species_colors) +
    scale_x_discrete(labels = c("0" = "No Growth\n(≤10 mm²)", "1" = "Growth\n(>10 mm²)"))
  
  # Water content plot
  water_growth_plot <- ggplot(growth_faecal_data, 
                             aes(x = growth_success_binary, y = water_content_0dpi, fill = species)) +
    geom_boxplot(alpha = 0.7, position = position_dodge(width = 0.8)) +
    geom_point(aes(color = species), alpha = 0.6, size = 1.5,
               position = position_jitterdodge(jitter.width = 0.2, dodge.width = 0.8)) +
    labs(
      title = "B) Initial Water Content vs Growth Success by Species",
      subtitle = "P. ostreatus vs G. lucidum comparison",
      x = "Growth Outcome",
      y = "Water Content at 0 DPI (%)",
      fill = "Species",
      color = "Species"
    ) +
    theme_publication() +
    scale_fill_manual(values = species_colors) +
    scale_color_manual(values = species_colors) +
    scale_x_discrete(labels = c("0" = "No Growth\n(≤10 mm²)", "1" = "Growth\n(>10 mm²)"))
  
  # E. coli plot
  ecoli_growth_plot <- ggplot(growth_faecal_data, 
                              aes(x = growth_success_binary, y = log_ecoli_0dpi, fill = species)) +
    geom_boxplot(alpha = 0.7, position = position_dodge(width = 0.8)) +
    geom_point(aes(color = species), alpha = 0.6, size = 1.5,
               position = position_jitterdodge(jitter.width = 0.2, dodge.width = 0.8)) +
    labs(
      title = "C) Initial E. coli Concentration vs Growth Success by Species",
      subtitle = "P. ostreatus vs G. lucidum comparison",
      x = "Growth Outcome",
      y = "Log10(E. coli CFU/g + 1)",
      fill = "Species",
      color = "Species"
    ) +
    theme_publication() +
    scale_fill_manual(values = species_colors) +
    scale_color_manual(values = species_colors) +
    scale_x_discrete(labels = c("0" = "No Growth\n(≤10 mm²)", "1" = "Growth\n(>10 mm²)"))
  
  # Combine plots
  combined_growth_plot <- grid.arrange(
    ph_growth_plot, 
    water_growth_plot, 
    ecoli_growth_plot, 
    ncol = 1
  )
  
  # Save combined plot
  ggsave("figures/faecal_characteristics_growth_exp1_2.png", 
         combined_growth_plot, 
         width = 10, 
         height = 12, 
         dpi = 300)
}

# ============================================
# SUMMARY REPORT
# ============================================

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("All visualizations saved to 'figures/' directory\n")
cat("Processed data saved to 'data/processed/' directory\n")

# Create summary table for export
summary_table <- experiment_1_2_analysis %>%
  group_by(species) %>%
  summarise(
    n_samples = n(),
    growth_success_rate = sum(growth_status_14dpi %in% c("Growth, no contamination", "Growth, contaminated")) / n() * 100,
    mean_weight_change = mean(weight_percent_change, na.rm = TRUE),
    mean_ph_change = mean(ph_14dpi - ph_0dpi, na.rm = TRUE),
    mean_ecoli_reduction = mean(ecoli_log_reduction, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_ecoli_reduction))

# Save summary table
write.csv(summary_table, "results/experiment_1_2_summary.csv", row.names = FALSE)
cat("\nSummary table saved to 'results/experiment_1_2_summary.csv'\n")

# Print final summary
cat("\n=== KEY FINDINGS ===\n")
cat("Top 3 species by E. coli reduction:\n")
print(summary_table %>% 
      select(species, mean_ecoli_reduction) %>%
      head(3))

cat("\nTop 3 species by weight reduction:\n")
print(summary_table %>% 
      arrange(mean_weight_change) %>%
      select(species, mean_weight_change) %>%
      head(3))
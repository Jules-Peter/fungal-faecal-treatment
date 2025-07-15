###Read files from raw data repository
#Growthspeed analysis
#Calculate growth speed per day
# Calculate growth per day

library("tidyverse")
library("googlesheets4")

######## Formatting the growth speed data showing are size change for 7, 14, and 21 days post inoculation (dpi)#########

exp_growth_speed <- experiment_1_1 |>
  left_join(growth_speed_1_1)|>
  ### Adding dpi calculated from starting date and picture date
  mutate(dpi = as.numeric(date -starting_date,
                          units = "days"))
#separate the columns that are constant per experiment_id.
#    We'll use distinct() to make sure we only keep one row for these
 
exp_growth_speed_base <- exp_growth_speed  |>
  select(id_treatment, id_inoc, id_faeces, `weight_0dpi`, `weight_14dpi`) |>
  distinct()
  
#Pivot the 'area size' column based on 'dpi'.
#create new columns like area_size_0, area_size_7, etc.
exp_area_size_pivot <- exp_growth_speed |>
  select(id_treatment, dpi, `area_size`) |>
  drop_na(area_size)|>
  pivot_wider(names_from = dpi,values_from = `area_size`,
    names_prefix = "area_size_")

# Join the base information with the pivoted area sizes.
# left_join to ensure all experiment_ids from the base info are kept.
growth_speed_analysis <- left_join(exp_growth_speed_base, exp_area_size_pivot, by = "id_treatment")

### Save growth speed as csv in processed
write_csv(growth_speed_analysis, "data/processed/growth_speed_analysis.csv")

############ Preparing tables for bacterial analysis ###############
bacteria_conc <- bacteria_1_1|>
  mutate(cfu_ecoli_end = ecoli_counted*dilution_ecoli/sample_weight)|>
  mutate(cfu_enterococcus_end = enterococcus_counted*dilution_enterococcus/sample_weight)

faeces_conc <- faeces_1_1|>
  mutate(cfu_ecoli_start = e_coli_counted_1*dilution_factor_ecoli_1/sample_weight_1)|>
  mutate(cfu_enterococcus_start = enterococcus_counted*dilution_factor_enterococcus/sample_weight)

exp_bacteria <-left_join(experiment_1_1, bacteria_conc, by="id_treatment")
bacteria_exp_faeces <- left_join(exp_bacteria, faeces_conc, by="id_faeces")
bacteria_joined <-left_join(bacteria_exp_faeces, inoculum_1_1)

### Select for relevant coloumns
bacteria_selected <- bacteria_joined |>
  select(id_treatment, species, cfu_ecoli_end, cfu_enterococcus_end, cfu_ecoli_start, cfu_enterococcus_start)

###Calculate log-change for each treatment
bacteria_analysis <- bacteria_selected|>
  mutate(log_change_ecoli= log10(cfu_ecoli_end/cfu_ecoli_start))|>
  mutate( log_change_enterococcus= log10(cfu_enterococcus_end/cfu_enterococcus_start))

glimpse(bacteria_analysis)

### Save bacteria analysis as csv in processed
write_csv(bacteria_analysis, "data/processed/bacteria_analysis.csv")  
write_rds(bacteria_analysis, "data/processed/bacteria_analysis.rds")


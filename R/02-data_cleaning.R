###Read files from raw data repository
#Growthspeed analysis
#Calculate growth speed per day
# Calculate growth per day

library("tidyverse")
library("googlesheets4")


###Formatting the faeces table
faeces_1_1_processed <- faeces_1_1 |>
  mutate(e_coli_mean = ((e_coli_counted_1 * dilution_factor_ecoli / sample_weight_1) +
                        (e_coli_counted_2 * dilution_factor_ecoli / sample_weight_2) +
                        (e_coli_counted_3 * dilution_factor_ecoli / sample_weight_3)) / 3) |>
   select(id_faeces, ph, e_coli_mean, water_content)
### Link the faeces table to the experiment table   
experiment_faeces <- experiment_1_1 |>
  left_join(faeces_1_1_processed, by = "id_faeces")|>
  mutate(dry_weight_0dpi = as.numeric((100-water_content)*weight_0dpi/100))|>
  rename(ph_0dpi = ph)
### Formatting the inoculum table
inoculum_processed <- inoculum_1_1|>
  select(id_inoc, species)
### Link the faeces table to the experiment table    
experiment_faeces_inoc <- experiment_faeces |>
  left_join(inoculum_processed, by = "id_inoc")

area_size_wide <- experiment_faeces_inoc |>
  select(id_treatment, starting_date) |>
  left_join(growth_speed_1_1, by = "id_treatment") |>
  mutate(dpi = as.numeric(date - starting_date, units = "days")) |>
  filter(!is.na(dpi)) |>  # Remove rows where dpi is NA
  select(id_treatment, dpi, area_size) |>
  pivot_wider(
    names_from = dpi,
    values_from = area_size,
    names_prefix = "area_size_"
  )
###Join area size data to the data frame
experiment_faeces_inoc_area <- experiment_faeces_inoc |>
  left_join(area_size_wide, by = "id_treatment")

###Formatting the bacteria table
bacteria_ecoli <- bacteria_1_1 |>
  mutate(e_coli_conc_14dpi = ecoli_counted * dilution_ecoli / sample_weight) |>
  select(id_treatment, e_coli_conc)
###Joining_bacteria_table
experiment_data_cleaned <- experiment_faeces_inoc_area |>
  left_join(bacteria_ecoli, by = "id_treatment")

###save as csv file
write_csv(experiment_data_cleaned, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/experiment_data_cleaned.csv")

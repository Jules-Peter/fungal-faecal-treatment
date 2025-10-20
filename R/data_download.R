# Data Download Script
# Downloads data from Google Sheets and saves as CSV files in data/raw/

# Install and load required packages
install.packages(c("googlesheets4", "readr"))
library(googlesheets4)
library(readr)

# Set authentication to FALSE for public sheets
gs4_auth()
getwd()

setwd("C:/Users/jupeter/gitrepos/fungal-faecal-treatment")

# Download and save data files
print("Downloading bacteria_1_1...")
bacteria_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/1HEGDEres6dtpPC9Hlje8mq1gSiPV5tv6HVcqMCTcm7Q/edit?usp=drive_link")
# Convert specific columns to numeric - handle list columns and NULLs
bacteria_1_1$sample_weight <- sapply(bacteria_1_1$sample_weight, function(x) if(is.null(x)) NA else as.numeric(x))
bacteria_1_1$dilution_ecoli <- sapply(bacteria_1_1$dilution_ecoli, function(x) if(is.null(x)) NA else as.numeric(x))
bacteria_1_1$ecoli_counted <- sapply(bacteria_1_1$ecoli_counted, function(x) if(is.null(x)) NA else as.numeric(x))
write_csv(bacteria_1_1, "data/raw/bacteria_1_1.csv")

print("Downloading experiment_1_1...")
experiment_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/1LAyaN5P7wxgKNc9Acbh59-fOWWVrjkTOBtTCqOmxAc8/edit?usp=drive_link")
# Convert specific columns to numeric - handle list columns and NULLs
experiment_1_1$weight_0dpi <- sapply(experiment_1_1$weight_0dpi, function(x) if(is.null(x)) NA else as.numeric(x))
experiment_1_1$weight_14dpi <- sapply(experiment_1_1$weight_14dpi, function(x) if(is.null(x)) NA else as.numeric(x))
experiment_1_1$water_content_14dpi <- sapply(experiment_1_1$water_content_14dpi, function(x) if(is.null(x)) NA else as.numeric(x))
experiment_1_1$ph_14dpi <- sapply(experiment_1_1$ph_14dpi, function(x) if(is.null(x)) NA else as.numeric(x))
write_csv(experiment_1_1, "data/raw/experiment_1_1.csv")

print("Downloading faeces_1_1...")
faeces_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/15zEkXV1cOHz2bjWpk8h_SMbINThnYcgxCV30DCnaMOo/edit?usp=drive_link")
write_csv(faeces_1_1, "data/raw/faeces_1_1.csv")

print("Downloading growth_speed_1_1...")
growth_speed_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/14VSVuUM32Q5M2XNoXCCtOmAFMrl_rKPtyenp6XVz_dg/edit?usp=drive_link")
# Convert specific columns to numeric - handle list columns and NULLs
growth_speed_1_1$area_size <- sapply(growth_speed_1_1$area_size, function(x) if(is.null(x)) NA else as.numeric(x))
growth_speed_1_1$growth_description <- sapply(growth_speed_1_1$growth_description, function(x) if(is.null(x)) NA else as.numeric(x))
growth_speed_1_1$contamination_area <- sapply(growth_speed_1_1$contamination_area, function(x) if(is.null(x)) NA else as.numeric(x))
growth_speed_1_1$reproductive_structures <- sapply(growth_speed_1_1$reproductive_structures, function(x) if(is.null(x)) NA else as.numeric(x))
write_csv(growth_speed_1_1, "data/raw/growth_speed_1_1.csv")

print("Downloading inoculum_1_1...")
inoculum_1_1 <- read_sheet("https://docs.google.com/spreadsheets/d/1A6j-FTdwOlPrr494TVFlIqkjl4RCOjVuNB03TEnBH2M/edit?usp=drive_link")
write_csv(inoculum_1_1, "data/raw/inoculum_1_1.csv")

print("Downloading bacteria_1_2...")
bacteria_1_2 <- read_sheet("https://docs.google.com/spreadsheets/d/1LZ93eFsPkDSIuqE9ukEx0c7I55tu8QWFKH_8O0FjzM0/edit?usp=drive_link")
# Convert specific columns to numeric - handle list columns and NULLs
bacteria_1_2$sample_weight <- sapply(bacteria_1_2$sample_weight, function(x) if(is.null(x)) NA else as.numeric(x))
bacteria_1_2$dilution_ecoli <- sapply(bacteria_1_2$dilution_ecoli, function(x) if(is.null(x)) NA else as.numeric(x))
bacteria_1_2$ecoli_counted <- sapply(bacteria_1_2$ecoli_counted, function(x) if(is.null(x)) NA else as.numeric(x))
write_csv(bacteria_1_2, "data/raw/bacteria_1_2.csv")

print("Downloading experiment_1_2...")
experiment_1_2 <- read_sheet("https://docs.google.com/spreadsheets/d/1cEfLjsuaZQkzh39N6xsVv5oE1H0rhik8sG5bpml5838/edit?usp=drive_link")
# Convert specific columns to numeric - handle list columns and NULLs
experiment_1_2$weight_0dpi <- sapply(experiment_1_2$weight_0dpi, function(x) if(is.null(x)) NA else as.numeric(x))
experiment_1_2$weight_14dpi <- sapply(experiment_1_2$weight_14dpi, function(x) if(is.null(x)) NA else as.numeric(x))
experiment_1_2$water_content_14dpi <- sapply(experiment_1_2$water_content_14dpi, function(x) if(is.null(x)) NA else as.numeric(x))
experiment_1_2$ph_14dpi <- sapply(experiment_1_2$ph_14dpi, function(x) if(is.null(x)) NA else as.numeric(x))
write_csv(experiment_1_2, "data/raw/experiment_1_2.csv")

print("Downloading faeces_1_2...")
faeces_1_2 <- read_sheet("https://docs.google.com/spreadsheets/d/1IIkRdeRqByZfyBpUxYUKsn_kG-H6Sq40YUI4_UwVxxk/edit?usp=drive_link")
write_csv(faeces_1_2, "data/raw/faeces_1_2.csv")

print("Downloading growth_speed_1_2...")
growth_speed_1_2 <- read_sheet("https://docs.google.com/spreadsheets/d/1MtmhVEGaDRYoEzw0Zycs-WVkFHsdN-frSA0i2Du6zEw/edit?usp=drive_link")
# Convert specific columns to numeric - handle list columns and NULLs
growth_speed_1_2$area_size <- sapply(growth_speed_1_2$area_size, function(x) if(is.null(x)) NA else as.numeric(x))
growth_speed_1_2$growth_description <- sapply(growth_speed_1_2$growth_description, function(x) if(is.null(x)) NA else as.numeric(x))
growth_speed_1_2$contamination_area <- sapply(growth_speed_1_2$contamination_area, function(x) if(is.null(x)) NA else as.numeric(x))
growth_speed_1_2$reproductive_structures <- sapply(growth_speed_1_2$reproductive_structures, function(x) if(is.null(x)) NA else as.numeric(x))
write_csv(growth_speed_1_2, "data/raw/growth_speed_1_2.csv")

print("Downloading inoculum_1_2...")
inoculum_1_2 <- read_sheet("https://docs.google.com/spreadsheets/d/1A6j-FTdwOlPrr494TVFlIqkjl4RCOjVuNB03TEnBH2M/edit?usp=drive_link")
write_csv(inoculum_1_2, "data/raw/inoculum_1_2.csv")

print("All files downloaded successfully to data/raw/")


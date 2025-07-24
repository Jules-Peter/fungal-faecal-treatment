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

###Writing the files in git hup directory follow up
write_csv(bacteria_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/bacteria_1_1.csv")
write_csv(experiment_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/experiment_1_1.csv")
write_csv(faeces_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/faeces_1_1.csv")
write_csv(growth_speed_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/growth_speed_1_1.csv")
write_csv(inoculum_1_1, "C:/Users/jupeter/gitrepos/fungal-faecal-treatment/data/raw/inoculum_1_1.csv")


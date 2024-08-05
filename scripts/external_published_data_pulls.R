# This script is for resources already published elsewhere on Open Data
# We should link to these datasets in our package rather than generate new tables here
# Retaining this script to keep track of these resources
# Delete this file when no longer needed

# SAFER on open data ------------------------------------------------------
# Data:
# https://data.ca.gov/dataset/safer-failing-and-at-risk-drinking-water-systems

dw_risk_raw <- read_csv("data-raw/Drinking_Water_Risk_Assessment.csv")

dw_population <- dw_risk_raw |> 
  select(WATER_SYSTEM_NUMBER, POPULATION) |> 
  rename(pwsid = WATER_SYSTEM_NUMBER,
         population = POPULATION)
write_csv(dw_population, "data/population_clean.csv")

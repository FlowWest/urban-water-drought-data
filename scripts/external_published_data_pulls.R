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


# supply and demand -------------------------------------------------------

# These data are published here: https://data.ca.gov/dataset/urws-conservation-supply-demand
# Represents Monthly CR (2014-2023) and currently reported on SAFER (2023-present)

supply_demand_query <- paste0("https://data.ca.gov/api/3/action/",
                              "datastore_search_sql?",
                              "sql=",
                              URLencode("SELECT * from \"f4d50112-5fb5-4066-b45c-44696b10a49e\""))

supply_demand_list_sql <- fromJSON(supply_demand_query)
supply_demand_raw_data <- supply_demand_list_sql$result$records

water_shortage <- supply_demand_raw_data |> 
  select(ORG_ID, WATER_SYSTEM_ID, SUPPLIER_NAME, REPORT_PERIOD_START_DATE, REPORT_PERIOD_END_DATE, DWR_STANDARD_LEVEL) |> 
  rename(org_id = ORG_ID,
         pwsid = WATER_SYSTEM_ID,
         supplier_name = SUPPLIER_NAME,
         start_date = REPORT_PERIOD_START_DATE,
         end_date = REPORT_PERIOD_END_DATE,
         water_shortage_level = DWR_STANDARD_LEVEL) |> 
  mutate(supplier_name = tolower(supplier_name),
         # clean up levels, assume if multiple listed than the higher level should be applied
         water_shortage_level = case_when(water_shortage_level == "1 (Less than 10% Shortage), 2 (10-19% Shortage)" ~ "2 (10-19% Shortage)",
                                          water_shortage_level == "2 (10-19% Shortage), Not Applicable" ~ "2 (10-19% Shortage)",
                                          water_shortage_level == "0 (No Shortage Level Invoked), 2 (10-19% Shortage)" ~ "2 (10-19% Shortage)",
                                          water_shortage_level == "Not Applicable" ~ NA,
                                          water_shortage_level == "WSCP Does Not Include Stages" ~ NA,
                                          T ~ water_shortage_level)) |> 
  # levels were applied beginning in 2022
  filter(year(start_date) > 2021)
write_csv(water_shortage, "data/water_shortage.csv")

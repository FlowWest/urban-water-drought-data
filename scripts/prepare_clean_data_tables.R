# The goal of this script is to process raw data tables. 
# TODO functionalize/automate (right now just manually pull data tables)
library(tidyverse)
library(jsonlite)


# metadata ----------------------------------------------------------------
# This information is maintained currently in a google sheet and will need to be updated

metadata <- read_sheet("https://docs.google.com/spreadsheets/d/1iy-4uUer18B2OhuWAOPXQYU9vgNuMiEPySQmZIsGO4k/edit#gid=0")
write_csv(metadata, "data/metadata.csv")


# Crosswalk ---------------------------------------------------------------

# Download the whole dataset using a SQL query
crosswalk_query <- paste0("https://data.ca.gov/api/3/action/",
                                      "datastore_search_sql?",
                                      "sql=",
                                      URLencode("SELECT * from \"dc42f085-75d8-48e0-b795-8ede6ee576c2\""))

crosswalk_list_sql <- fromJSON(crosswalk_query)
crosswalk_raw_data <- crosswalk_list_sql$result$records

crosswalk <- crosswalk_raw_data |> 
  mutate(ORG_ID = as.numeric(ORG_ID)) |> 
  rename(org_id = ORG_ID,
         pwsid = PWSID)

# AWSDA -------------------------------------------------------------------

# Note that when downloading data it is really hard to tell if it is the 2022 or 2023 data

#AWSDA - 2022
# Data here:
# https://wuedata.water.ca.gov/wsda_export
# Data reporting guidance:
# https://wuedata.water.ca.gov/public/public_resources/3517484366/AWSDA-Final-Guidance-4-2022.pdf 
awsda_demand_raw <- readxl::read_xls("data-raw/wsda_table2.xls")
awsda_supply_raw <- readxl::read_xls("data-raw/wsda_table3.xls")

# 2022

# CURRENTLY NOT USED: Demand and Supply Tables by dwr_org_id, month, year, demand_or_supply, type

# as of 3/12/2024 call with julie decided we don't need the demand/supply broken up to this level (type of demand/supply)
awsda_demand_format <- awsda_demand_raw |> 
  select(ORG_ID, POTABLE_NONPOTABLE, DEMANDS_SERVED, JULY_DEMANDS, AUGUST_DEMANDS, SEPTEMBER_DEMANDS,
         OCTOBER_DEMANDS, NOVEMBER_DEMANDS, DECEMBER_DEMANDS, JANUARY_DEMANDS, FEBRUARY_DEMANDS, 
         MARCH_DEMANDS, APRIL_DEMANDS, MAY_DEMANDS, JUNE_DEMANDS) |> 
  rename(Jul = JULY_DEMANDS,
         Aug = AUGUST_DEMANDS,
         Sep = SEPTEMBER_DEMANDS,
         Oct = OCTOBER_DEMANDS,
         Nov = NOVEMBER_DEMANDS,
         Dec = DECEMBER_DEMANDS,
         Jan = JANUARY_DEMANDS,
         Feb = FEBRUARY_DEMANDS,
         Mar = MARCH_DEMANDS,
         Apr = APRIL_DEMANDS,
         May = MAY_DEMANDS,
         Jun = JUNE_DEMANDS,
         org_id = ORG_ID,
         potable_nonpotable = POTABLE_NONPOTABLE,
         demand_supply_type = DEMANDS_SERVED) |> 
  pivot_longer(Jul:Jun, names_to = "month", values_to = "acre_feet") |> 
  mutate(demand_supply_type = tolower(demand_supply_type),
         demand_supply = "demand",
         # need to confirm year type and consider adding variable to specify year- type (june - july)
         # June 2022 - July 2023
         year = 2022)

dput(unique(awsda_demand_format$demand_supply_type))
dput(unique(awsda_demand_format$potable_nonpotable))
dput(unique(awsda_demand_format$month))


awsda_supply_format <- awsda_supply_raw |> 
  select(ORG_ID, POTABLE_NONPOTABLE, SUPPLIES, JULY_DEMANDS, AUGUST_DEMANDS, SEPTEMBER_DEMANDS,
         OCTOBER_DEMANDS, NOVEMBER_DEMANDS, DECEMBER_DEMANDS, JANUARY_DEMANDS, FEBRUARY_DEMANDS, 
         MARCH_DEMANDS, APRIL_DEMANDS, MAY_DEMANDS, JUNE_DEMANDS) |> 
  rename(Jul = JULY_DEMANDS,
         Aug = AUGUST_DEMANDS,
         Sep = SEPTEMBER_DEMANDS,
         Oct = OCTOBER_DEMANDS,
         Nov = NOVEMBER_DEMANDS,
         Dec = DECEMBER_DEMANDS,
         Jan = JANUARY_DEMANDS,
         Feb = FEBRUARY_DEMANDS,
         Mar = MARCH_DEMANDS,
         Apr = APRIL_DEMANDS,
         May = MAY_DEMANDS,
         Jun = JUNE_DEMANDS,
         org_id = ORG_ID,
         potable_nonpotable = POTABLE_NONPOTABLE,
         demand_supply_type = SUPPLIES) |> 
  pivot_longer(Jul:Jun, names_to = "month", values_to = "acre_feet") |> 
  mutate(demand_supply_type = tolower(demand_supply_type),
         demand_supply = "supply",
         # need to confirm year type and consider adding variable to specify year- type (june - july)
         # June 2022 - July 2023
         year = 2022)

dput(unique(awsda_supply_format$demand_supply_type))
dput(unique(awsda_supply_format$potable_nonpotable))
dput(unique(awsda_supply_format$month))

awsda_clean <- bind_rows(awsda_demand_format,
                         awsda_supply_format) |> 
  select(org_id, year, month, demand_supply, potable_nonpotable, demand_supply_type, acre_feet)

# assessment table - right now only including for potable water; nonpotable is optional response
awsda_assessment_raw <- readxl::read_xlsx("data-raw/wsda_table4.xlsx")

pot_no_action_list <-
  c(
    "POT_SHORT_NO_ACTION_JULY",
    "POT_SHORT_NO_ACTION_AUGUST",
    "POT_SHORT_NO_ACTION_SEPTEMBER",
    "POT_SHORT_NO_ACTION_OCTOBER",
    "POT_SHORT_NO_ACTION_NOVEMBER",
    "POT_SHORT_NO_ACTION_DECEMBER",
    "POT_SHORT_NO_ACTION_JANUARY",
    "POT_SHORT_NO_ACTION_FEBRUARY",
    "POT_SHORT_NO_ACTION_MARCH",
    "POT_SHORT_NO_ACTION_APRIL",
    "POT_SHORT_NO_ACTION_MAY",
    "POT_SHORT_NO_ACTION_JUNE",
    "POT_SHORT_NO_ACTION_TOTAL"
  )
pot_augm_list <-
  c(
    "POT_AUGM_JULY",
    "POT_AUGM_AUGUST",
    "POT_AUGM_SEPTEMBER",
    "POT_AUGM_OCTOBER",
    "POT_AUGM_NOVEMBER",
    "POT_AUGM_DECEMBER",
    "POT_AUGM_JANUARY",
    "POT_AUGM_FEBRUARY",
    "POT_AUGM_MARCH",
    "POT_AUGM_APRIL",
    "POT_AUGM_MAY",
    "POT_AUGM_JUNE",
    "POT_AUGM_TOTAL"
  )
pot_red_list <- c(
  "POT_SHORT_DEM_RED_JULY",
  "POT_SHORT_DEM_RED_AUGUST",
  "POT_SHORT_DEM_RED_SEPTEMBER",
  "POT_SHORT_DEM_RED_OCTOBER",
  "POT_SHORT_DEM_RED_NOVEMBER",
  "POT_SHORT_DEM_RED_DECEMBER",
  "POT_SHORT_DEM_RED_JANUARY",
  "POT_SHORT_DEM_RED_FEBRUARY",
  "POT_SHORT_DEM_RED_MARCH",
  "POT_SHORT_DEM_RED_APRIL",
  "POT_SHORT_DEM_RED_MAY",
  "POT_SHORT_DEM_RED_JUNE",
  "POT_SHORT_DEM_RED_TOTAL"
)

# TODO how do we want to handle NA - we could include so explicit that no augmentation action provided or convert to 0
awsda_assessment_aug <- awsda_assessment_raw |> 
  select(ORG_ID, all_of(pot_augm_list)) |> 
  rename(Jul = POT_AUGM_JULY, 
         Aug = POT_AUGM_AUGUST, 
         Sep = POT_AUGM_SEPTEMBER,
         Oct = POT_AUGM_OCTOBER,
         Nov = POT_AUGM_NOVEMBER, 
         Dec = POT_AUGM_DECEMBER,
         Jan = POT_AUGM_JANUARY,
         Feb = POT_AUGM_FEBRUARY,
         Mar = POT_AUGM_MARCH, 
         Apr = POT_AUGM_APRIL,
         May = POT_AUGM_MAY,
         Jun = POT_AUGM_JUNE,
         Annual = POT_AUGM_TOTAL,
         org_id = ORG_ID) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "acre_feet") |> 
  mutate(shortage_action_type = "supply augmentation")

awsda_assessment_red <- awsda_assessment_raw |> 
  select(ORG_ID, all_of(pot_red_list)) |> 
  rename(Jul = POT_SHORT_DEM_RED_JULY, 
         Aug = POT_SHORT_DEM_RED_AUGUST, 
         Sep = POT_SHORT_DEM_RED_SEPTEMBER,
         Oct = POT_SHORT_DEM_RED_OCTOBER,
         Nov = POT_SHORT_DEM_RED_NOVEMBER, 
         Dec = POT_SHORT_DEM_RED_DECEMBER,
         Jan = POT_SHORT_DEM_RED_JANUARY,
         Feb = POT_SHORT_DEM_RED_FEBRUARY,
         Mar = POT_SHORT_DEM_RED_MARCH, 
         Apr = POT_SHORT_DEM_RED_APRIL,
         May = POT_SHORT_DEM_RED_MAY,
         Jun = POT_SHORT_DEM_RED_JUNE,
         Annual = POT_SHORT_DEM_RED_TOTAL,
         org_id = ORG_ID) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "acre_feet") |> 
  mutate(shortage_action_type = "demand reduction")

awsda_assessment_no_action <- awsda_assessment_raw |> 
  select(ORG_ID, all_of(pot_no_action_list)) |> 
  rename(Jul = POT_SHORT_NO_ACTION_JULY, 
         Aug = POT_SHORT_NO_ACTION_AUGUST, 
         Sep = POT_SHORT_NO_ACTION_SEPTEMBER,
         Oct = POT_SHORT_NO_ACTION_OCTOBER,
         Nov = POT_SHORT_NO_ACTION_NOVEMBER, 
         Dec = POT_SHORT_NO_ACTION_DECEMBER,
         Jan = POT_SHORT_NO_ACTION_JANUARY,
         Feb = POT_SHORT_NO_ACTION_FEBRUARY,
         Mar = POT_SHORT_NO_ACTION_MARCH, 
         Apr = POT_SHORT_NO_ACTION_APRIL,
         May = POT_SHORT_NO_ACTION_MAY,
         Jun = POT_SHORT_NO_ACTION_JUNE,
         Annual = POT_SHORT_NO_ACTION_TOTAL,
         org_id = ORG_ID) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "acre_feet") |> 
  mutate(shortage_action_type = "no action")

awsda_assessment_clean <- bind_rows(awsda_assessment_aug,
                                    awsda_assessment_red,
                                    awsda_assessment_no_action) |> 
  mutate(year = case_when(month %in% c("Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Annual") ~ 2022,
                          T ~ 2023),
         is_annual = ifelse(month == "Annual", T, F)) |> 
  select(org_id, year, month, is_annual, shortage_action_type, acre_feet)

# TODO We need to decide how we want to handle multiple PWSIDs
# awsda_assessment_pwsid_check <- awsda_assessment_raw |> 
#   rename(org_id = ORG_ID) |> 
#   left_join(crosswalk |> 
#               select(org_id,
#                      pwsid), relationship = "many-to-many") 
# awsda_assessment_pwsid <- awsda_assessment_clean |> 
#   left_join(crosswalk |> 
#               select(org_id,
#                      pwsid), relationship = "many-to-many")
# 
# pwsid_to_check <- awsda_assessment_pwsid |> 
#   distinct(org_id, pwsid) |> 
#   group_by(org_id) |> 
#   tally() |> 
#   filter(n > 1)

write_csv(awsda_assessment_clean, "data/monthly_dry_year_outlook.csv")


# UWMP --------------------------------------------------------------------

# UWMP 2020
# drought risk assessment
# calculate supplies - demand
# Data:
# https://wuedata.water.ca.gov/uwmp_export_2020.asp
# Guidance:
# https://water.ca.gov/-/media/DWR-Website/Web-Pages/Programs/Water-Use-And-Efficiency/Urban-Water-Use-Efficiency/Urban-Water-Management-Plans/Final-2020-UWMP-Guidebook/UWMP-Guidebook-2020---Final-032921.pdf

uwmp_drought_risk_raw <- readxl::read_xlsx("data-raw/uwmp_table_7_5_2020.xlsx")

uwmp_2021 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2021, TOTAL_SUPPLIES_2021, SUPPLY_AUG_BENEFIT_2021, USE_REDUCT_BENEFIT_2021) |> 
  rename(org_id = ORG_ID) |> 
  mutate(SUPPLY_AUG_BENEFIT_2021 = ifelse(is.na(SUPPLY_AUG_BENEFIT_2021), 0, SUPPLY_AUG_BENEFIT_2021),
         USE_REDUCT_BENEFIT_2021 = ifelse(is.na(USE_REDUCT_BENEFIT_2021), 0, USE_REDUCT_BENEFIT_2021),
         shortage_no_action = TOTAL_SUPPLIES_2021 - TOTAL_WATER_USE_2021,
         shortage_action = shortage_no_action + SUPPLY_AUG_BENEFIT_2021 + USE_REDUCT_BENEFIT_2021) |> 
  select(-c(TOTAL_WATER_USE_2021, TOTAL_SUPPLIES_2021, SUPPLY_AUG_BENEFIT_2021, USE_REDUCT_BENEFIT_2021)) |> 
  pivot_longer(shortage_no_action:shortage_action, names_to = "is_action_included", values_to = "acre_feet") |> 
  mutate(year = 2021,
         is_action_included = ifelse(is_action_included == "shortage_action", T, F))

uwmp_2022 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2022, TOTAL_SUPPLIES_2022, SUPPLY_AUG_BENEFIT_2022, USE_REDUCT_BENEFIT_2022) |> 
  rename(org_id = ORG_ID) |> 
  mutate(SUPPLY_AUG_BENEFIT_2022 = ifelse(is.na(SUPPLY_AUG_BENEFIT_2022), 0, SUPPLY_AUG_BENEFIT_2022),
         USE_REDUCT_BENEFIT_2022 = ifelse(is.na(USE_REDUCT_BENEFIT_2022), 0, USE_REDUCT_BENEFIT_2022),
         shortage_no_action = TOTAL_SUPPLIES_2022 - TOTAL_WATER_USE_2022,
         shortage_action = shortage_no_action + SUPPLY_AUG_BENEFIT_2022 + USE_REDUCT_BENEFIT_2022) |> 
  select(-c(TOTAL_WATER_USE_2022, TOTAL_SUPPLIES_2022, SUPPLY_AUG_BENEFIT_2022, USE_REDUCT_BENEFIT_2022)) |> 
  pivot_longer(shortage_no_action:shortage_action, names_to = "is_action_included", values_to = "acre_feet") |> 
  mutate(year = 2022,
         is_action_included = ifelse(is_action_included == "shortage_action", T, F))

uwmp_2023 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2023, TOTAL_SUPPLIES_2023, SUPPLY_AUG_BENEFIT_2023, USE_REDUCT_BENEFIT_2023) |> 
  rename(org_id = ORG_ID) |> 
  mutate(SUPPLY_AUG_BENEFIT_2023 = ifelse(is.na(SUPPLY_AUG_BENEFIT_2023), 0, SUPPLY_AUG_BENEFIT_2023),
         USE_REDUCT_BENEFIT_2023 = ifelse(is.na(USE_REDUCT_BENEFIT_2023), 0, USE_REDUCT_BENEFIT_2023),
         shortage_no_action = TOTAL_SUPPLIES_2023 - TOTAL_WATER_USE_2023,
         shortage_action = shortage_no_action + SUPPLY_AUG_BENEFIT_2023 + USE_REDUCT_BENEFIT_2023) |> 
  select(-c(TOTAL_WATER_USE_2023, TOTAL_SUPPLIES_2023, SUPPLY_AUG_BENEFIT_2023, USE_REDUCT_BENEFIT_2023)) |> 
  pivot_longer(shortage_no_action:shortage_action, names_to = "is_action_included", values_to = "acre_feet") |> 
  mutate(year = 2023,
         is_action_included = ifelse(is_action_included == "shortage_action", T, F))

uwmp_2024 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2024, TOTAL_SUPPLIES_2024, SUPPLY_AUG_BENEFIT_2024, USE_REDUCT_BENEFIT_2024) |> 
  rename(org_id = ORG_ID) |> 
  mutate(SUPPLY_AUG_BENEFIT_2024 = ifelse(is.na(SUPPLY_AUG_BENEFIT_2024), 0, SUPPLY_AUG_BENEFIT_2024),
         USE_REDUCT_BENEFIT_2024 = ifelse(is.na(USE_REDUCT_BENEFIT_2024), 0, USE_REDUCT_BENEFIT_2024),
         shortage_no_action = TOTAL_SUPPLIES_2024 - TOTAL_WATER_USE_2024,
         shortage_action = shortage_no_action + SUPPLY_AUG_BENEFIT_2024 + USE_REDUCT_BENEFIT_2024) |> 
  select(-c(TOTAL_WATER_USE_2024, TOTAL_SUPPLIES_2024, SUPPLY_AUG_BENEFIT_2024, USE_REDUCT_BENEFIT_2024)) |> 
  pivot_longer(shortage_no_action:shortage_action, names_to = "is_action_included", values_to = "acre_feet") |> 
  mutate(year = 2024,
         is_action_included = ifelse(is_action_included == "shortage_action", T, F))

uwmp_2025 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2025, TOTAL_SUPPLIES_2025, SUPPLY_AUG_BENEFIT_2025, USE_REDUCT_BENEFIT_2025) |> 
  rename(org_id = ORG_ID) |> 
  mutate(SUPPLY_AUG_BENEFIT_2025 = ifelse(is.na(SUPPLY_AUG_BENEFIT_2025), 0, SUPPLY_AUG_BENEFIT_2025),
         USE_REDUCT_BENEFIT_2025 = ifelse(is.na(USE_REDUCT_BENEFIT_2025), 0, USE_REDUCT_BENEFIT_2025),
         shortage_no_action = TOTAL_SUPPLIES_2025 - TOTAL_WATER_USE_2025,
         shortage_action = shortage_no_action + SUPPLY_AUG_BENEFIT_2025 + USE_REDUCT_BENEFIT_2025) |> 
  select(-c(TOTAL_WATER_USE_2025, TOTAL_SUPPLIES_2025, SUPPLY_AUG_BENEFIT_2025, USE_REDUCT_BENEFIT_2025)) |> 
  pivot_longer(shortage_no_action:shortage_action, names_to = "is_action_included", values_to = "acre_feet") |> 
  mutate(year = 2025,
         is_action_included = ifelse(is_action_included == "shortage_action", T, F))
uwmp_drought_risk_clean <- bind_rows(uwmp_2021,
                                     uwmp_2022,
                                     uwmp_2023,
                                     uwmp_2024,
                                     uwmp_2025) |> 
  select(org_id, year, is_action_included, acre_feet)

# TODO We need to decide how we want to handle multiple PWSIDs
# dra_pwsid_check <- uwmp_drought_risk_raw |>
#   rename(org_id = ORG_ID) |>
#   left_join(crosswalk |>
#               select(org_id,
#                      pwsid), relationship = "many-to-many")
# dra_pwsid <- uwmp_drought_risk_clean |>
#   left_join(crosswalk |>
#               select(org_id,
#                      pwsid), relationship = "many-to-many")
# 
# dra_pwsid_to_check <- dra_pwsid |>
#   distinct(org_id, pwsid) |>
#   group_by(org_id) |>
#   tally() |>
#   filter(n > 1)

write_csv(uwmp_drought_risk_clean, "data/drought_risk_assessment.csv")

# Monthly CR --------------------------------------------------------------
# Data:
# https://data.ca.gov/dataset/drinking-water-public-water-system-operations-monthly-water-production-and-conservation-information

# TODO requires cleaning up the shortage stage. water_shortage_stage is a mess, dwr_shortage_stage only exists for 2022-2023
cr_raw <- read_csv("data-raw/monthly_CR.csv")

cr_format <- cr_raw |> 
  select(public_water_system_id, reporting_month, water_shortage_contingency_stage_invoked, 
         water_shortage_level_indicator, dwr_state_standard_level_corresponding_to_stage) |> 
  rename(pwsid = public_water_system_id,
         water_shortage_stage = water_shortage_contingency_stage_invoked,
         shortage_greater_10_percent = water_shortage_level_indicator,
         dwr_water_shortage_stage = dwr_state_standard_level_corresponding_to_stage) |> 
  mutate(month = month(reporting_month, label = T),
         year = year(reporting_month),
         shortage_greater_10_percent = case_when(shortage_greater_10_percent == "Yes" ~ T,
                                                 shortage_greater_10_percent == "No" ~ F),
         water_shortage_stage = tolower(water_shortage_stage)) |> 
  select(-reporting_month) |> 
  select(pwsid, year, month, water_shortage_stage, dwr_water_shortage_stage, shortage_greater_10_percent)

unique(cr_format$water_shortage_stage)
unique(cr_format$dwr_water_shortage_stage)

write_csv(cr_format, "data/water_shortage_level_clean.csv")


# Rafa flatfile (eAR) -----------------------------------------------------
# Data:
# Provided via email by Rafa
rafa_raw <- readxl::read_xlsx("data-raw/EAR_FLAT_FILE_WP_WD_FORMAT.xlsx", sheet = 2)

rafa_format <- rafa_raw |> 
  select(PWSID, Year, `MONTH CALC`, `Produced or Delivery`, TYPE, Population, `WP AF CALCULATED`) |> 
  rename(pwsid = PWSID,
         year = Year,
         month = `MONTH CALC`,
         produced_or_delivery = `Produced or Delivery`,
         produced_or_delivery_type = TYPE,
         population = Population,
         acre_feet = `WP AF CALCULATED`) |> 
  mutate(produced_or_delivery = tolower(produced_or_delivery),
         produced_or_delivery_type = tolower(produced_or_delivery_type),
         month = tolower(month),
         month = case_when(month == "january" ~ "Jan",
                           month == "february" ~ "Feb",
                           month == "march" ~ "Mar",
                           month == "april" ~ "Apr",
                           month == "may" ~ "May",
                           month == "june" ~ "Jun",
                           month == "july" ~ "Jul",
                           month == "august" ~ "Aug",
                           month == "september" ~ "Sep",
                           month == "october" ~ "Oct",
                           month == "november" ~ "Nov",
                           month == "december" ~ "Dec",
                           month == "annual" ~ "Annual"))

unique(rafa_format$produced_or_delivery)
dput(unique(rafa_format$produced_or_delivery_type))
dput(unique(rafa_format$month))

write_csv(rafa_format, "data/production_delivery_volume_clean.csv")


# eAR ---------------------------------------------------------------------
# Data: https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/ear.html

# TODO need to reformat the source names - get feedback from group whether want to invest
# time in that

# ear_sources_name <- ear_2022_raw |> 
#   filter(QuestionName %in% c("SourcesGWGrid", "SourcesGWNotListedGrid", "SourcesSWGrid",
#                              "SourcesSWNotListedGrid")) |> 
#   select(WSID, QuestionName, QuestionResults) |> 
#   rename(pwsid = WSID,
#          source_type = QuestionName,
#          source_name = QuestionResults) |> 
#   mutate(
#          # reporting year but need to deal with handling of this so it is not manual
#          year = 2022) |> 
#   select(pwsid, year, source_type, source_name)
# write_csv(ear_sources_name, "data/source_name_clean.csv")

# Create number of sources table
ear_tibble <- tibble(years = c(2022:2013),
                     files = c("data-raw/ear_release_data_03082024.txt",
                               "data-raw/EAR_2021_results.text",
                               "data-raw/2020RY_PortalClosed_032822.txt",
                               "data-raw/2019RY_Resultset_08192021.txt",
                               "data-raw/EARSurveyResults_2018RY.txt",
                               "data-raw/EARSurveyResults_2017RY.txt",
                               "data-raw/EARSurveyResults_2016RY.txt",
                               "data-raw/EARSurveyResults_2015RY.txt",
                               "data-raw/EARSurveyResults_2014RY.txt",
                               "data-raw/2013RY_v2.txt"))

pull_ear_sources_number <- function(files, years) {
  data <- vroom::vroom(files, delim = "\t")
  if(years > 2019) {
    data <- data |> 
      rename(PWSID = WSID) 
  }
  else{
    data <- data |> 
      mutate(QuestionName = case_when(QuestionName == "Sources GW Approved" ~ "SourcesGWApproved",
                                      QuestionName == "Sources SW Approved" ~ "SourcesSWApproved",
                                      QuestionName == "Sources PGW Approved" ~ "SourcesPGWApproved",
                                      QuestionName == "Sources PSW Approved" ~ "SourcesPSWApproved",
                                      QuestionName == "Sources SB Approved" ~ "SourcesSBApproved",
                                      QuestionName == "Sources EI Approved" ~ "SourcesEIApproved",
                                      QuestionName == "Sources GW New" ~ "SourcesGWNew",
                                      QuestionName == "Sources SW New" ~ "SourcesSWNew",  
                                      QuestionName == "Sources PGW New" ~ "SourcesPGWNew",
                                      QuestionName == "Sources PSW New" ~ "SourcesPSWNew", 
                                      QuestionName == "Sources SB New" ~ "SourcesSBNew",
                                      QuestionName == "Sources EI New" ~ "SourcesEINew",
                                      # QuestionName == "Sources I Approved" ~ "SourcesIApproved",
                                      # QuestionName == "Sources P Approved" ~ "SourcesPApproved",
                                      T ~ QuestionName))
  }
  data <- data |> 
  filter(QuestionName %in% c("SourcesGWApproved", 
                             "SourcesSWApproved", "SourcesPGWApproved", 
                             "SourcesPSWApproved",  "SourcesSBApproved", 
                             "SourcesEIApproved", "SourcesGWNew",
                             "SourcesSWNew",  "SourcesPGWNew",
                             "SourcesPSWNew", "SourcesSBNew",
                             "SourcesEINew"  
                             #"SourcesIApproved", 
                             #"SourcesPApproved"
                             )) |> 
  select(PWSID, QuestionName, QuestionResults) |> 
  group_by(PWSID, QuestionName) |> 
  summarize(QuestionResults = max(QuestionResults)) |> 
  mutate(source_status = ifelse(grepl("Approved", QuestionName), "approved", "new"),
         QuestionName = case_when(grepl("PSW", QuestionName) ~ "purchased surface water",
                                  grepl("PGW", QuestionName) ~ "purchased grounwater",
                                  grepl("GW", QuestionName) ~ "groundwater",
                                  grepl("SW", QuestionName) ~ "surface water",
                                  grepl("SB", QuestionName) ~ "standby sources",
                                  grepl("EI", QuestionName) ~ "emergency interties"),
         QuestionResults = as.numeric(QuestionResults),
         year = years) |> 
  rename(source_type = QuestionName,
         number_of_sources = QuestionResults,
         pwsid = PWSID) |> 
    select(pwsid, year, source_type, source_status, number_of_sources)
  write_csv(data, file = paste0("data-raw/ear_sources_",years,".csv"))
}

pmap(ear_tibble, pull_ear_sources_number)

file_shortcut <- "data-raw/ear_sources_"
sources_number_combined <- bind_rows(
  read_csv(paste0(file_shortcut, "2022.csv")),
  read_csv(paste0(file_shortcut, "2021.csv")),
  read_csv(paste0(file_shortcut, "2020.csv")),
  read_csv(paste0(file_shortcut, "2019.csv")),
  read_csv(paste0(file_shortcut, "2018.csv")),
  read_csv(paste0(file_shortcut, "2017.csv")),
  read_csv(paste0(file_shortcut, "2016.csv")),
  read_csv(paste0(file_shortcut, "2015.csv")),
  read_csv(paste0(file_shortcut, "2014.csv")),
  read_csv(paste0(file_shortcut, "2013.csv"))
)

write_csv(sources_number_combined, "data/number_sources.csv")

# checking what happens when we add dwr_id
# check_crosswalk <- sources_number_combined |> 
#   left_join(crosswalk |> 
#               select(pwsid, org_id))
# 
# filter(check_crosswalk, is.na(org_id)) |> 
#   distinct(year, pwsid) |> 
#   group_by(year) |> 
#   tally()
# 
# check_crosswalk |> 
#   distinct(year, pwsid) |> 
#   group_by(year) |> 
#   tally()

# SAFER on open data ------------------------------------------------------
# Data:
# https://data.ca.gov/dataset/safer-failing-and-at-risk-drinking-water-systems

dw_risk_raw <- read_csv("data-raw/Drinking_Water_Risk_Assessment.csv")

dw_population <- dw_risk_raw |> 
  select(WATER_SYSTEM_NUMBER, POPULATION) |> 
  rename(pwsid = WATER_SYSTEM_NUMBER,
         population = POPULATION)
write_csv(dw_population, "data/population_clean.csv")

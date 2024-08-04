# The goal of this script is to process raw data tables. 
# TODO functionalize/automate (right now just manually pull data tables)
library(tidyverse)
library(jsonlite)
library(readxl)
library(googlesheets4)


# helpers -----------------------------------------------------------------
month_mapping <- tibble(month_number = 1:12,
                        month_abbrev = c("Jan", "Feb", "Mar", "Apr", "May",
                                         "Jun", "Jul", "Aug", "Sep", "Oct",
                                         "Nov", "Dec"),
                        month_full = c("January", "February", "March", "April",
                                       "May", "June", "July", "August", "September",
                                       "October", "November", "December")) |> 
  mutate(month_abbrev = tolower(month_abbrev),
         month_full = tolower(month_full))
# metadata ----------------------------------------------------------------
# This information is maintained currently in a google sheet and will need to be updated
# Note that this requires authentication to be set up
# metadata <- read_sheet("https://docs.google.com/spreadsheets/d/1iy-4uUer18B2OhuWAOPXQYU9vgNuMiEPySQmZIsGO4k/edit#gid=0")
# write_csv(metadata, "data/metadata.csv")


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
write_csv(crosswalk, "data/other_data/id_crosswalk.csv")

# pull org_id and PWSID lookup from UWMP. This should be used with UWMP and AWSDA data
# There are DWR_ID with multiple PWSID
# Note there are some NA org_id
# Note that there are some with CA pwsid
uwmp_dwr_id_pwsid_raw <- readxl::read_xlsx("data-raw/uwmp_table_2_1_r_2020.xlsx")
uwmp_dwr_id_pwsid <- uwmp_dwr_id_pwsid_raw |> 
  select(ORG_ID, PUBLIC_WATER_SYSTEM_NUMBER) |> 
  rename(org_id = ORG_ID,
         pwsid = PUBLIC_WATER_SYSTEM_NUMBER) |> 
  group_by(org_id) |> 
  summarize(n = length(unique(pwsid)),
            pwsid = paste(unique(pwsid), collapse = ", ")) |> 
  mutate(is_multiple_pwsid = ifelse(n > 1, T, F)) |> 
  filter(!is.na(org_id)) |> 
  select(-n)

# AWSDA: monthly water shortage outlook -------------------------------------------------------------------

# general information is contained in table 1
awsda_info_raw <- readxl::read_xls("data-raw/wsda_table1_info_2024.xls")

awsda_info <- awsda_info_raw |> 
  select(ORG_ID, VOLUME_UNIT, START_MONTH, END_MONTH, REPORTING_INTERVAL) |> 
   rename(org_id = ORG_ID,
          start_month = START_MONTH,
          end_month = END_MONTH,
          reporting_interval = REPORTING_INTERVAL) |> 
  mutate(start_month = tolower(start_month),
         end_month = tolower(end_month))

awsda_assessment_raw <- readxl::read_xls("data-raw/wsda_table4_2024.xls") |> 
  distinct() # there are duplicate records for 1752

# need to replace 0 with NA for those that only report annually - implemente

## variable lists #######
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

pot_no_action_perc_list <-
  c(
    "POT_PERC_NO_ACTION_JULY",
    "POT_PERC_NO_ACTION_AUGUST",
    "POT_PERC_NO_ACTION_SEPTEMBER",
    "POT_PERC_NO_ACTION_OCTOBER",
    "POT_PERC_NO_ACTION_NOVEMBER",
    "POT_PERC_NO_ACTION_DECEMBER",
    "POT_PERC_NO_ACTION_JANUARY",
    "POT_PERC_NO_ACTION_FEBRUARY",
    "POT_PERC_NO_ACTION_MARCH",
    "POT_PERC_NO_ACTION_APRIL",
    "POT_PERC_NO_ACTION_MAY",
    "POT_PERC_NO_ACTION_JUNE",
    "POT_PERC_NO_ACTION_TOTAL"
  )

pot_short_level_list <-
  c(
    "POT_SHORT_LEVEL_JULY",
    "POT_SHORT_LEVEL_AUGUST",
    "POT_SHORT_LEVEL_SEPTEMBER",
    "POT_SHORT_LEVEL_OCTOBER",
    "POT_SHORT_LEVEL_NOVEMBER",
    "POT_SHORT_LEVEL_DECEMBER",
    "POT_SHORT_LEVEL_JANUARY",
    "POT_SHORT_LEVEL_FEBRUARY",
    "POT_SHORT_LEVEL_MARCH",
    "POT_SHORT_LEVEL_APRIL",
    "POT_SHORT_LEVEL_MAY",
    "POT_SHORT_LEVEL_JUNE",
    "POT_SHORT_LEVEL_TOTAL"
  )

pot_rev_list <-
  c(
    "POT_REV_SHORT_JULY",
    "POT_REV_SHORT_AUGUST",
    "POT_REV_SHORT_SEPTEMBER",
    "POT_REV_SHORT_OCTOBER",
    "POT_REV_SHORT_NOVEMBER",
    "POT_REV_SHORT_DECEMBER",
    "POT_REV_SHORT_JANUARY",
    "POT_REV_SHORT_FEBRUARY",
    "POT_REV_SHORT_MARCH",
    "POT_REV_SHORT_APRIL",
    "POT_REV_SHORT_MAY",
    "POT_REV_SHORT_JUNE",
    "POT_REV_SHORT_TOTAL"
  )

pot_rev_perc_list <-
  c(
    "POT_REV_PERC_JULY",
    "POT_REV_PERC_AUGUST",
    "POT_REV_PERC_SEPTEMBER",
    "POT_REV_PERC_OCTOBER",
    "POT_REV_PERC_NOVEMBER",
    "POT_REV_PERC_DECEMBER",
    "POT_REV_PERC_JANUARY",
    "POT_REV_PERC_FEBRUARY",
    "POT_REV_PERC_MARCH",
    "POT_REV_PERC_APRIL",
    "POT_REV_PERC_MAY",
    "POT_REV_PERC_JUNE",
    "POT_REV_PERC_TOTAL"
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

org_id_supplier_name <- awsda_assessment_raw |> 
  select(ORG_ID, WATER_SUPPLIER_NAME, SUPPLIER_TYPE) |> 
  rename(org_id = ORG_ID,
         supplier_name = WATER_SUPPLIER_NAME,
         supplier_type = SUPPLIER_TYPE) |> 
  mutate(supplier_name = tolower(supplier_name))

## action benefits #######
# This pulls the supply augmentation benefit by month (water added by this action)
awsda_assessment_aug <- awsda_assessment_raw |> 
  select(ORG_ID, SUPPLIER_TYPE, all_of(pot_augm_list)) |> 
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
         org_id = ORG_ID,
         supplier_type = SUPPLIER_TYPE) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "benefit_supply_augmentation_acre_feet") |> 
  mutate(is_wscp_action = T)
# This pulls the demand reduction benefit by month (water added by this action)
awsda_assessment_red <- awsda_assessment_raw |> 
  select(ORG_ID, SUPPLIER_TYPE, all_of(pot_red_list)) |> 
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
         org_id = ORG_ID,
         supplier_type = SUPPLIER_TYPE) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "benefit_demand_reduction_acre_feet") |> 
  mutate(is_wscp_action = T)


## without action ----------------------------------------------

# even though the data are published with 0s I think they should be NAs 
# for those that only report annually etc - this has been implemented

# Note that there are duplicate data for ORG_ID 1752 and 2179

# water short (or surplus) without action
awsda_assessment_no_action <- awsda_assessment_raw |> 
  select(ORG_ID, SUPPLIER_TYPE, all_of(pot_no_action_list)) |> 
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
         org_id = ORG_ID,
         supplier_type = SUPPLIER_TYPE) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "shortage_surplus_acre_feet") |> 
  mutate(is_wscp_action = F) 

# ck <- awsda_assessment_no_action |>  group_by(org_id, month, supplier_type) |> tally() |>  filter(n>1)

# percent water short (or surplus) without action
awsda_assessment_no_action_perc <- awsda_assessment_raw |> 
  select(ORG_ID, SUPPLIER_TYPE, all_of(pot_no_action_perc_list)) |> 
  rename(Jul = POT_PERC_NO_ACTION_JULY, 
         Aug = POT_PERC_NO_ACTION_AUGUST, 
         Sep = POT_PERC_NO_ACTION_SEPTEMBER,
         Oct = POT_PERC_NO_ACTION_OCTOBER,
         Nov = POT_PERC_NO_ACTION_NOVEMBER, 
         Dec = POT_PERC_NO_ACTION_DECEMBER,
         Jan = POT_PERC_NO_ACTION_JANUARY,
         Feb = POT_PERC_NO_ACTION_FEBRUARY,
         Mar = POT_PERC_NO_ACTION_MARCH, 
         Apr = POT_PERC_NO_ACTION_APRIL,
         May = POT_PERC_NO_ACTION_MAY,
         Jun = POT_PERC_NO_ACTION_JUNE,
         Annual = POT_PERC_NO_ACTION_TOTAL,
         org_id = ORG_ID,
         supplier_type = SUPPLIER_TYPE) |> 
  mutate(across(Jul:Annual, as.numeric)) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "shortage_surplus_percent")

# standard shortage level based on percent water short
awsda_assessment_short_level <- awsda_assessment_raw |> 
  select(ORG_ID, SUPPLIER_TYPE, all_of(pot_short_level_list)) |> 
  rename(Jul = POT_SHORT_LEVEL_JULY, 
         Aug = POT_SHORT_LEVEL_AUGUST, 
         Sep = POT_SHORT_LEVEL_SEPTEMBER,
         Oct = POT_SHORT_LEVEL_OCTOBER,
         Nov = POT_SHORT_LEVEL_NOVEMBER, 
         Dec = POT_SHORT_LEVEL_DECEMBER,
         Jan = POT_SHORT_LEVEL_JANUARY,
         Feb = POT_SHORT_LEVEL_FEBRUARY,
         Mar = POT_SHORT_LEVEL_MARCH, 
         Apr = POT_SHORT_LEVEL_APRIL,
         May = POT_SHORT_LEVEL_MAY,
         Jun = POT_SHORT_LEVEL_JUNE,
         Annual = POT_SHORT_LEVEL_TOTAL,
         org_id = ORG_ID,
         supplier_type = SUPPLIER_TYPE) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "state_standard_shortage_level")


## with action -------------------------------------------------
awsda_assessment_action <- awsda_assessment_raw |> 
  select(ORG_ID, SUPPLIER_TYPE, all_of(pot_rev_list)) |> 
  rename(Jul = POT_REV_SHORT_JULY, 
         Aug = POT_REV_SHORT_AUGUST, 
         Sep = POT_REV_SHORT_SEPTEMBER,
         Oct = POT_REV_SHORT_OCTOBER,
         Nov = POT_REV_SHORT_NOVEMBER, 
         Dec = POT_REV_SHORT_DECEMBER,
         Jan = POT_REV_SHORT_JANUARY,
         Feb = POT_REV_SHORT_FEBRUARY,
         Mar = POT_REV_SHORT_MARCH, 
         Apr = POT_REV_SHORT_APRIL,
         May = POT_REV_SHORT_MAY,
         Jun = POT_REV_SHORT_JUNE,
         Annual = POT_REV_SHORT_TOTAL,
         org_id = ORG_ID,
         supplier_type = SUPPLIER_TYPE) |> 
  mutate(across(Jul:Annual, as.numeric)) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "shortage_surplus_acre_feet") |> 
  mutate(is_wscp_action = T)

awsda_assessment_action_perc <- awsda_assessment_raw |> 
  select(ORG_ID, SUPPLIER_TYPE, all_of(pot_rev_perc_list)) |> 
  rename(Jul = POT_REV_PERC_JULY, 
         Aug = POT_REV_PERC_AUGUST, 
         Sep = POT_REV_PERC_SEPTEMBER,
         Oct = POT_REV_PERC_OCTOBER,
         Nov = POT_REV_PERC_NOVEMBER, 
         Dec = POT_REV_PERC_DECEMBER,
         Jan = POT_REV_PERC_JANUARY,
         Feb = POT_REV_PERC_FEBRUARY,
         Mar = POT_REV_PERC_MARCH, 
         Apr = POT_REV_PERC_APRIL,
         May = POT_REV_PERC_MAY,
         Jun = POT_REV_PERC_JUNE,
         Annual = POT_REV_PERC_TOTAL,
         org_id = ORG_ID,
         supplier_type = SUPPLIER_TYPE) |> 
  mutate(across(Jul:Annual, as.numeric)) |> 
  pivot_longer(Jul:Annual, names_to = "month", values_to = "shortage_surplus_percent") 


awsda_assessment_clean <- left_join(awsda_assessment_no_action, awsda_assessment_no_action_perc) |> 
  left_join(awsda_assessment_short_level) |> 
  bind_rows(left_join(awsda_assessment_action, awsda_assessment_action_perc)) |> 
  left_join(org_id_supplier_name) |> 
  left_join(awsda_assessment_aug) |> # add on rows for augmentation volume
  left_join(awsda_assessment_red) |> # add on rows for reduction volume
  left_join(awsda_info) |> 
  left_join(month_mapping |> # convert start_month to abbrev
              rename(start_month = month_full)) |> 
  mutate(start_month = month_abbrev) |> 
  select(-c(month_number, month_abbrev)) |> 
  left_join(month_mapping |> # convert end_month to abbrev
             rename(end_month = month_full)) |> 
  mutate(end_month = month_abbrev) |> 
  select(-c(month_number, month_abbrev)) |> 
  left_join(uwmp_dwr_id_pwsid) |> # add pwsid from the UWMP, note that there are 17 NAs, need to include multiple PWSID in same row otherwise will get duplicate data
  mutate(forecast_year = case_when(month %in% c("Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Annual") ~ 2024,
                          T ~ 2025),
         is_annual = ifelse(month == "Annual", T, F),
         month = tolower(month),
         supplier_type = tolower(supplier_type),
         reporting_interval = tolower(reporting_interval),
         # convert all to AF (although this is not how it is on WUE, it is more usable this way)
         shortage_surplus_acre_feet = case_when(VOLUME_UNIT == "MG" ~ shortage_surplus_acre_feet*3.06887,
                                                VOLUME_UNIT == "CCF(HCF)" ~ shortage_surplus_acre_feet*0.0023,
                                                VOLUME_UNIT == "AF" ~ shortage_surplus_acre_feet),
         benefit_supply_augmentation_acre_feet = case_when(VOLUME_UNIT == "MG" ~ benefit_supply_augmentation_acre_feet*3.06887,
                                                           VOLUME_UNIT == "CCF(HCF)" ~ benefit_supply_augmentation_acre_feet*0.0023,
                                                           VOLUME_UNIT == "AF" ~ benefit_supply_augmentation_acre_feet),
         benefit_demand_reduction_acre_feet = case_when(VOLUME_UNIT == "MG" ~ benefit_demand_reduction_acre_feet*3.06887,
                                                           VOLUME_UNIT == "CCF(HCF)" ~ benefit_demand_reduction_acre_feet*0.0023,
                                                           VOLUME_UNIT == "AF" ~ benefit_demand_reduction_acre_feet),
         # if reporting annually then all monthly values will be NA, note that for one that says they report annually there are monthly values
         shortage_surplus_acre_feet = case_when(reporting_interval == "annually (1 data point per year)" & month != "annual" ~ NA,
                                                T ~ shortage_surplus_acre_feet),
         shortage_surplus_percent = case_when(reporting_interval == "annually (1 data point per year)" & month != "annual" ~ NA,
                                              T ~ shortage_surplus_percent),
         # for bimonthly then all values where 0 are actually NA
         shortage_surplus_acre_feet = case_when(reporting_interval == "bi-monthly (6 data points per year)" & shortage_surplus_acre_feet == 0 ~ NA,
                                                T ~ shortage_surplus_acre_feet)) |> 
  select(org_id, pwsid, is_multiple_pwsid, supplier_name, supplier_type, reporting_interval, start_month, end_month, 
         forecast_year, month, is_annual, is_wscp_action, shortage_surplus_acre_feet, 
         shortage_surplus_percent, state_standard_shortage_level, benefit_demand_reduction_acre_feet, 
         benefit_supply_augmentation_acre_feet) |> 
  rename(forecast_month = month,
         reporting_start_month = start_month,
         reporting_end_month = end_month)

# checking values for when reporting interval is not monthly! Decided to change - this has been implemented
# unique(awsda_assessment_clean$reporting_interval)
# ck_annual <- filter(awsda_assessment_clean, reporting_interval == "annually (1 data point per year)")
# ck_bimonth <- filter(awsda_assessment_clean, reporting_interval == "bi-monthly (6 data points per year)")


# checks
# benefits should be NA when wscp_action = F
try(if(nrow(filter(awsda_assessment_clean, !is.na(benefit_supply_augmentation_acre_feet) & is_wscp_action == F)) > 0)
  stop("Supply benefits exist when there are not WSCP actions"))
try(if(nrow(filter(awsda_assessment_clean, !is.na(benefit_demand_reduction_acre_feet) & is_wscp_action == F)) > 0)
  stop("Demand benefits exist when there are not WSCP actions"))
min(awsda_assessment_clean$shortage_surplus_acre_feet)
max(awsda_assessment_clean$shortage_surplus_acre_feet)
min(awsda_assessment_clean$shortage_surplus_percent, na.rm = T)
max(awsda_assessment_clean$shortage_surplus_percent, na.rm = T)

# trying to apply the pwsid
# there are 17 without pwsid
awsda_assessment_clean |> filter(is.na(pwsid)) |> distinct(org_id) |> tally()

write_csv(awsda_assessment_clean, "data/monthly_dry_year_outlook.csv")


# UWMP: five year water shortage outlook --------------------------------------------------------------------
# TODO convert this to pull from the Open Data dataset
# UWMP 2020
# drought risk assessment
# calculate supplies - demand
# Data:
# https://wuedata.water.ca.gov/uwmp_export_2020.asp
# Guidance:
# https://water.ca.gov/-/media/DWR-Website/Web-Pages/Programs/Water-Use-And-Efficiency/Urban-Water-Use-Efficiency/Urban-Water-Management-Plans/Final-2020-UWMP-Guidebook/UWMP-Guidebook-2020---Final-032921.pdf

uwmp_drought_risk_raw <- readxl::read_xlsx("data-raw/uwmp_table_7_5_2020.xlsx")

uwmp_org_id_supplier_name <- uwmp_drought_risk_raw |> 
  select(ORG_ID, WATER_SUPPLIER_NAME) |> 
  rename(org_id = ORG_ID,
         supplier_name = WATER_SUPPLIER_NAME) |> 
  mutate(supplier_name = tolower(supplier_name))
# originally had some calculated field but moving away from that to just include data that was reported

uwmp_2021 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2021, TOTAL_SUPPLIES_2021, SUPPLY_AUG_BENEFIT_2021, USE_REDUCT_BENEFIT_2021) |> 
  rename(org_id = ORG_ID,
         water_use_acre_feet = TOTAL_WATER_USE_2021,
         water_supplies_acre_feet = TOTAL_SUPPLIES_2021,
         benefit_supply_augmentation_acre_feet = SUPPLY_AUG_BENEFIT_2021,
         benefit_demand_reduction_acre_feet = USE_REDUCT_BENEFIT_2021) |> 
  mutate(year = 2021)

uwmp_2022 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2022, TOTAL_SUPPLIES_2022, SUPPLY_AUG_BENEFIT_2022, USE_REDUCT_BENEFIT_2022) |> 
  rename(org_id = ORG_ID,
         water_use_acre_feet = TOTAL_WATER_USE_2022,
         water_supplies_acre_feet = TOTAL_SUPPLIES_2022,
         benefit_supply_augmentation_acre_feet = SUPPLY_AUG_BENEFIT_2022,
         benefit_demand_reduction_acre_feet = USE_REDUCT_BENEFIT_2022) |> 
  mutate(year = 2022)

uwmp_2023 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2023, TOTAL_SUPPLIES_2023, SUPPLY_AUG_BENEFIT_2023, USE_REDUCT_BENEFIT_2023) |> 
  rename(org_id = ORG_ID,
         water_use_acre_feet = TOTAL_WATER_USE_2023,
         water_supplies_acre_feet = TOTAL_SUPPLIES_2023,
         benefit_supply_augmentation_acre_feet = SUPPLY_AUG_BENEFIT_2023,
         benefit_demand_reduction_acre_feet = USE_REDUCT_BENEFIT_2023) |> 
  mutate(year = 2023)

uwmp_2024 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2024, TOTAL_SUPPLIES_2024, SUPPLY_AUG_BENEFIT_2024, USE_REDUCT_BENEFIT_2024) |> 
  rename(org_id = ORG_ID,
         water_use_acre_feet = TOTAL_WATER_USE_2024,
         water_supplies_acre_feet = TOTAL_SUPPLIES_2024,
         benefit_supply_augmentation_acre_feet = SUPPLY_AUG_BENEFIT_2024,
         benefit_demand_reduction_acre_feet = USE_REDUCT_BENEFIT_2024) |> 
  mutate(year = 2024)

uwmp_2025 <- uwmp_drought_risk_raw |> 
  select(ORG_ID, TOTAL_WATER_USE_2025, TOTAL_SUPPLIES_2025, SUPPLY_AUG_BENEFIT_2025, USE_REDUCT_BENEFIT_2025) |> 
  rename(org_id = ORG_ID,
         water_use_acre_feet = TOTAL_WATER_USE_2025,
         water_supplies_acre_feet = TOTAL_SUPPLIES_2025,
         benefit_supply_augmentation_acre_feet = SUPPLY_AUG_BENEFIT_2025,
         benefit_demand_reduction_acre_feet = USE_REDUCT_BENEFIT_2025) |> 
  mutate(year = 2025)

uwmp_drought_risk_clean <- bind_rows(uwmp_2021,
                                     uwmp_2022,
                                     uwmp_2023,
                                     uwmp_2024,
                                     uwmp_2025) |> 
  filter(!is.na(org_id)) |> 
  left_join(uwmp_org_id_supplier_name) |> 
  left_join(uwmp_dwr_id_pwsid) |> # add pwsid from the UWMP, note that there are 32 NAs, need to include multiple PWSID in same row otherwise will get duplicate data
  select(org_id, pwsid, is_multiple_pwsid, supplier_name, year, water_use_acre_feet, water_supplies_acre_feet, benefit_supply_augmentation_acre_feet,
         benefit_demand_reduction_acre_feet)

min(uwmp_drought_risk_clean$water_supplies_acre_feet, na.rm = T)
max(uwmp_drought_risk_clean$water_supplies_acre_feet, na.rm = T)

min(uwmp_drought_risk_clean$water_use_acre_feet, na.rm = T)
max(uwmp_drought_risk_clean$water_use_acre_feet, na.rm = T)

min(uwmp_drought_risk_clean$benefit_supply_augmentation_acre_feet, na.rm = T)
max(uwmp_drought_risk_clean$benefit_supply_augmentation_acre_feet, na.rm = T)

min(uwmp_drought_risk_clean$benefit_demand_reduction_acre_feet, na.rm = T)
max(uwmp_drought_risk_clean$benefit_demand_reduction_acre_feet, na.rm = T)

# trying to apply the pwsid
# there are 17 without pwsid
uwmp_drought_risk_clean |> filter(is.na(pwsid)) |> distinct(org_id) |> tally()

write_csv(uwmp_drought_risk_clean, "data/five_year_outlook.csv")



# eAR number of sources ---------------------------------------------------------------------
# Data: https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/ear.html

# TODO decide if this is redundant of the source_name table
# This workflow is not automated. Are these data even being reported through eAR anymore?

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
) |> 
  left_join(crosswalk |>
              select(pwsid, org_id))

write_csv(sources_number_combined, "data/number_sources.csv")

# checking what happens when we add dwr_id
filter(sources_number_combined, is.na(org_id)) |>
  distinct(year, pwsid) |>
  group_by(year) |>
  tally()

sources_number_combined |>
  distinct(year, pwsid) |>
  group_by(year) |>
  tally()


# SAFER export from eric --------------------------------------------------
# TODO need to work through publishing this information and approvals needed

# Using the single water systems sheet because eric said that is the one to use. 
# TODO get more info on the sheet names
# TODO ask for information about facility_activity_status: difference between proposed and proposed - new
# TODO ask eric about sdwis vs safer water type; source_utilized? is this that different than status?
# Decided to keep facility id because it might be helpful later - though should find out who else uses this ID
# TODO ask julie - there is a bunch of pump and well info but don't think we want that
source_name_export <- read_xlsx("data-raw/20240509_SAFER_CLEARINGHOUSE_EXPORT - WDC.xlsx", sheet = "data_export_SingleWaterSystems")

source_name <- source_name_export |> 
  select(WATER_SYSTEM_ID, FACILITY_NAME, FACILITY_ACTIVITY_STATUS, FACILITY_AVAILABILITY, 
         FACILITY_TYPE, SDWIS_WATER_TYPE, CLEARINGHOUSE_WATER_TYPE, REPORTING_PERIOD_END_DATE, 
         REPORTING_PERIOD_START_DATE, LATITUDE_MEASURE, LONGITUDE_MEASURE, FACILITY_ID) |> 
  rename(pwsid = WATER_SYSTEM_ID,
         facility_id = FACILITY_ID,
         facility_name = FACILITY_NAME,
         facility_activity_status = FACILITY_ACTIVITY_STATUS,
         facility_availability = FACILITY_AVAILABILITY,
         facility_type = FACILITY_TYPE,
         sdwis_water_type = SDWIS_WATER_TYPE,
         safer_water_type = CLEARINGHOUSE_WATER_TYPE,
         start_date = REPORTING_PERIOD_START_DATE,
         end_date = REPORTING_PERIOD_END_DATE,
         latitude = LATITUDE_MEASURE,
         longitude = LONGITUDE_MEASURE) |> 
  distinct() |>  # there is some other variable in here but get duplicates when select only these variables
  mutate(across(facility_name:safer_water_type, tolower)) |> 
  select(pwsid, start_date, end_date, facility_id, facility_name, facility_activity_status, 
         facility_availability, facility_type, sdwis_water_type, safer_water_type, latitude, longitude)

source_name |> distinct(facility_name) |> tally() #4,563 unique source names
unique(source_name$facility_activity_status) # active, not available, inactive, proposed, proposed - new
unique(source_name$facility_availability) # permanent, emergency, interim, other, seasonal, not available
dput(unique(source_name$facility_type)) #c("Spring", "Consecutive Connection", "Well", "Purchased", "Non-Piped, Purchased", 
# "Intake", "Non-Purchased", "Reservoir", "Not Available", "Infiltration Gallery", 
# "Non-Piped, Non-Purchased", "Distribution System", "ST", "Clear Well", 
# "Treatment Plant")
dput(unique(source_name$safer_water_type)) #c("Spring Water", "Consecutive Connections", "Groundwater & GWUDI", 
# "Hauled Water", "Surface Water", "Not Available")
dput(unique(source_name$sdwis_water_type)) #c("Groundwater", "Surface Water", "Groundwater under the Direct Influence of Surface Water", 
# "Not Available")

write_csv(source_name, "data/source_name.csv")


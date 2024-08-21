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
# NOTE: Pulling new data for this table can not yet be automated as data are only available on WUE which requires
# click and download

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
  mutate(start_month = month_number) |> 
  select(-c(month_number, month_abbrev)) |> 
  left_join(month_mapping |> # convert end_month to abbrev
             rename(end_month = month_full)) |> 
  mutate(end_month = month_number) |> 
  select(-c(month_number, month_abbrev)) |> 
  left_join(uwmp_dwr_id_pwsid) |> # add pwsid from the UWMP, note that there are 17 NAs, need to include multiple PWSID in same row otherwise will get duplicate data
  mutate( shortage_surplus_acre_feet = case_when(VOLUME_UNIT == "MG" ~ shortage_surplus_acre_feet*3.06887,
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
          state_standard_shortage_level = case_when(reporting_interval == "annually (1 data point per year)" & month != "annual" ~ NA,
                                                    T ~ state_standard_shortage_level),
          # for bimonthly then all values where 0 are actually NA
          shortage_surplus_acre_feet = case_when(reporting_interval == "bi-monthly (6 data points per year)" & shortage_surplus_acre_feet == 0 ~ NA,
                                                 T ~ shortage_surplus_acre_feet),
          shortage_surplus_percent = case_when(reporting_interval == "bi-monthly (6 data points per year)" & shortage_surplus_percent == 0 ~ NA,
                                               T ~ shortage_surplus_percent),
          state_standard_shortage_level = case_when(reporting_interval == "bi-monthly (6 data points per year)" & is.na(shortage_surplus_acre_feet) ~ NA,
                                                    T ~ state_standard_shortage_level))

# This code chunk transitions to date format
awsda_assessment_final <- awsda_assessment_clean |> 
  mutate(report_year_start = case_when(start_month %in% 6:12 ~ 2024, # for those starting in june through dec this will be 2024
                                       T ~ 2025), # those starting in jan assumes 2025
         report_year_end = case_when(end_month %in% 6:12 ~ 2025,
                                     T ~ 2026),
         is_annual = ifelse(month == "Annual", T, F),
         month = tolower(month),
         supplier_type = tolower(supplier_type),
         reporting_interval = tolower(reporting_interval)) |> 
  left_join(month_mapping |> # convert start_month to abbrev
              rename(month = month_abbrev)) |> 
  mutate(month = month_number) |> 
  select(-c(month_number, month_full)) |> 
  # code to transition to use start and end dates rather than month and year
  mutate(reporting_start_date = as_date(paste0(report_year_start, "-", start_month, "-01")),
         fake_date = as_date(paste0(report_year_start, "-", end_month, "-01")),
         days_month = as.numeric(days_in_month(fake_date)),
         reporting_end_date = as_date(paste0(report_year_end, "-", end_month, "-", days_month)),
         forecast_year = case_when(start_month == 7 & month %in% 7:12 ~ 2024,
                                   start_month == 7 & month %in% 1:6 ~ 2025,
                                   start_month == 6 & month %in% 6:12 ~ 2024,
                                   start_month == 6 & month %in% 1:5 ~ 2025,
                                   start_month == 1 ~ 2025,
                                   start_month == 2 & month %in% 2:12 ~ 2025,
                                   start_month == 2 & month == 1 ~ 2026,
                                   start_month == 3 & month %in% 3:12 ~ 2025,
                                   start_month == 3 & month %in% 1:2 ~ 2026,
                                   start_month == 10 & month %in% 10:12 ~ 2024,
                                   start_month == 10 & month %in% 1:9 ~ 2025),
         forecast_start_date = case_when(is.na(month) ~ reporting_start_date,
                                         T ~ as_date(paste0(forecast_year, "-", month, "-01"))),
         days_month_f =  as.numeric(days_in_month(forecast_start_date)),
         forecast_end_date = case_when(is.na(month) ~ reporting_end_date,
                                       T ~ as_date(paste0(forecast_year, "-", month, "-", days_month_f)))) |> 
  select(org_id, pwsid, is_multiple_pwsid, supplier_name, supplier_type, reporting_interval, 
         reporting_start_date, reporting_end_date, forecast_start_date, forecast_end_date, forecast_month = month,
         is_annual, is_wscp_action, shortage_surplus_acre_feet, 
         shortage_surplus_percent, state_standard_shortage_level, benefit_demand_reduction_acre_feet, 
         benefit_supply_augmentation_acre_feet)

# checking values for when reporting interval is not monthly! Decided to change - this has been implemented
# unique(awsda_assessment_clean$reporting_interval)
# ck_annual <- filter(awsda_assessment_clean, reporting_interval == "annually (1 data point per year)")
# ck_bimonth <- filter(awsda_assessment_clean, reporting_interval == "bi-monthly (6 data points per year)")


# checks
# benefits should be NA when wscp_action = F
try(if(nrow(filter(awsda_assessment_final, !is.na(benefit_supply_augmentation_acre_feet) & is_wscp_action == F)) > 0)
  stop("Supply benefits exist when there are not WSCP actions"))
try(if(nrow(filter(awsda_assessment_final, !is.na(benefit_demand_reduction_acre_feet) & is_wscp_action == F)) > 0)
  stop("Demand benefits exist when there are not WSCP actions"))
min(awsda_assessment_final$shortage_surplus_acre_feet)
max(awsda_assessment_final$shortage_surplus_acre_feet)
min(awsda_assessment_final$shortage_surplus_percent, na.rm = T)
max(awsda_assessment_final$shortage_surplus_percent, na.rm = T)
min(awsda_assessment_final$benefit_demand_reduction_acre_feet, na.rm = T)
max(awsda_assessment_final$benefit_demand_reduction_acre_feet, na.rm = T)
min(awsda_assessment_final$benefit_supply_augmentation_acre_feet, na.rm = T)
max(awsda_assessment_final$benefit_supply_augmentation_acre_feet, na.rm = T)
dput(unique(awsda_assessment_final$state_standard_shortage_level))
unique(awsda_assessment_final$reporting_end_date)
unique(awsda_assessment_final$reporting_start_date)
min(awsda_assessment_final$reporting_start_date)
max(awsda_assessment_final$reporting_start_date)
min(awsda_assessment_final$reporting_end_date)
max(awsda_assessment_final$reporting_end_date)
min(awsda_assessment_final$forecast_end_date)
max(awsda_assessment_final$forecast_end_date)
min(awsda_assessment_final$forecast_start_date)
max(awsda_assessment_final$forecast_start_date)
# trying to apply the pwsid
# there are 17 without pwsid
awsda_assessment_final |> filter(is.na(pwsid)) |> distinct(org_id) |> tally()

write_csv(awsda_assessment_final, "data/monthly_dry_year_outlook.csv")


# UWMP: five year water shortage outlook --------------------------------------------------------------------
# Note could convert this to pull from the Open Data dataset - though only updated once every five years and guessing next update will be a different table
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
  mutate(uwmp_year = 2020) |> 
  select(org_id, pwsid, is_multiple_pwsid, supplier_name, year, uwmp_year, water_use_acre_feet, water_supplies_acre_feet, benefit_supply_augmentation_acre_feet,
         benefit_demand_reduction_acre_feet) |> 
  rename(forecast_year = year) |> glimpse()

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

uwmp_drought_risk_final <- uwmp_drought_risk_clean |> 
  mutate(forecast_start_date = as_date(paste0(forecast_year, "-01-01")),
         forecast_end_date = as_date(paste0(forecast_year, "-12-31"))) |> 
  select(org_id, pwsid, is_multiple_pwsid, supplier_name, uwmp_year, forecast_start_date, forecast_end_date,
         water_use_acre_feet, water_supplies_acre_feet, benefit_supply_augmentation_acre_feet,
         benefit_demand_reduction_acre_feet)

write_csv(uwmp_drought_risk_final, "data/five_year_outlook.csv")


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
  mutate(across(facility_name:safer_water_type, tolower),
         start_date = as_date(start_date),
         end_date = as_date(end_date),
         latitude = as.numeric(latitude),
         longitude = as.numeric(longitude)) |> 
  left_join(crosswalk |>
              select(pwsid, org_id)) |> 
  select(pwsid, org_id, start_date, end_date, facility_id, facility_name, facility_activity_status, 
         facility_availability, facility_type,  safer_water_type, latitude, longitude) |> 
  # decided to use safer water_type - should confirm with eric that this makes sense
  rename(water_type = safer_water_type) |> glimpse()

source_name |> distinct(facility_name) |> tally() #4,563 unique source names

# Metadata valuyes
dput(unique(source_name$facility_activity_status)) # active, not available, inactive, proposed, proposed - new
dput(unique(source_name$facility_availability)) # permanent, emergency, interim, other, seasonal, not available
dput(unique(source_name$facility_type)) #c("Spring", "Consecutive Connection", "Well", "Purchased", "Non-Piped, Purchased", 
# "Intake", "Non-Purchased", "Reservoir", "Not Available", "Infiltration Gallery", 
# "Non-Piped, Non-Purchased", "Distribution System", "ST", "Clear Well", 
# "Treatment Plant")
dput(unique(source_name$water_type)) #c("Spring Water", "Consecutive Connections", "Groundwater & GWUDI", 
# "Hauled Water", "Surface Water", "Not Available")
dput(unique(source_name$sdwis_water_type)) #c("Groundwater", "Surface Water", "Groundwater under the Direct Influence of Surface Water", 
# "Not Available")
min(source_name$start_date)
max(source_name$start_date)

min(source_name$end_date)
max(source_name$end_date)

min(source_name$latitude, na.rm = T)
max(source_name$latitude, na.rm = T)
min(source_name$longitude, na.rm = T)
max(source_name$longitude, na.rm = T)

mode(source_name$facility_name)
write_csv(source_name, "data/source_name.csv")

# current monthly shortage -------------------------------------------------------

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
                                          T ~ water_shortage_level),
         water_shortage_level = case_when(water_shortage_level == "0 (No Shortage Level Invoked)" ~ 0,
                                          water_shortage_level == "1 (Less than 10% Shortage)" ~ 1,
                                          water_shortage_level == "2 (10-19% Shortage)" ~ 2,
                                          water_shortage_level == "3 (20-29% Shortage)" ~ 3,
                                          water_shortage_level == "4 (30-39% Shortage)" ~ 4,
                                          water_shortage_level == "5 (40-49% Shortage)" ~ 5,
                                          T ~ NA_real_),
         start_date = as_date(start_date),
         end_date = as_date(end_date)) |> 
  # levels were applied beginning in 2022
  filter(year(start_date) > 2021) |> 
  rename(state_standard_shortage_level = water_shortage_level) # rename for consistency and clarity
write_csv(water_shortage, "data/actual_water_shortage_level.csv")

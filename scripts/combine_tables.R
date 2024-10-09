# This script attempts to join tables together as a test in usability

monthly_outlook <- read_csv("data/monthly_water_shortage_outlook.csv") |> glimpse()
five_year_outlook <- read_csv("data/five_year_water_shortage_outlook.csv") |> glimpse()
source_name <- read_csv("data/source_name.csv") |> glimpse()
actual_shortage <- read_csv("data/actual_water_shortage_level.csv") |> glimpse()
production_delivery <- read_csv("data/historical_production_delivery.csv") |> glimpse()

processed_five_year_outlook <- bind_rows(
  five_year_outlook |>
    select(-c(uwmp_year)) |>
    mutate(
      is_annual = T,
      is_wscp_action = F,
      benefit_demand_reduction_acre_feet = NA,
      benefit_supply_augmentation_acre_feet = NA,
      shortage_surplus_acre_feet = water_supplies_acre_feet - water_use_acre_feet,
      shortage_surplus_percent = (shortage_surplus_acre_feet /
                                    water_supplies_acre_feet) * 100
    ),
  five_year_outlook |>
    select(-c(uwmp_year)) |>
    mutate(
      is_annual = T,
      is_wscp_action = T,
      benefit_demand_reduction_acre_feet = ifelse(is.na(benefit_demand_reduction_acre_feet), 0, benefit_demand_reduction_acre_feet),
      benefit_supply_augmentation_acre_feet = ifelse(is.na(benefit_supply_augmentation_acre_feet), 0, benefit_supply_augmentation_acre_feet),
      water_supplies_acre_feet = water_supplies_acre_feet + benefit_supply_augmentation_acre_feet,
      benefit_demand_reduction_acre_feet = water_use_acre_feet - benefit_demand_reduction_acre_feet,
      shortage_surplus_acre_feet = water_supplies_acre_feet - water_use_acre_feet,
      shortage_surplus_percent = (shortage_surplus_acre_feet /
                                    water_supplies_acre_feet) * 100
    )
) |> 
  mutate(state_standard_shortage_level = case_when(shortage_surplus_percent >= 0 ~ 0,
                                                   shortage_surplus_percent < 0 & shortage_surplus_percent > -10 ~ 1,
                                                   shortage_surplus_percent <= -10 & shortage_surplus_percent > -20 ~ 2,
                                                   shortage_surplus_percent <= -20 & shortage_surplus_percent > -30 ~ 3,
                                                   shortage_surplus_percent <= -30 & shortage_surplus_percent > -40 ~ 4,
                                                   shortage_surplus_percent <= -40 & shortage_surplus_percent > -50 ~ 5,
                                                   shortage_surplus_percent <= -50 ~ 6))



forecast_megatable <- full_join(monthly_outlook |> 
                                  select(-c(reporting_interval, reporting_start_date, 
                                            reporting_end_date)),
                                processed_five_year_outlook) |>
  glimpse()

write_csv(forecast_megatable, "data/forecast_megatable.csv")

uwmp_org_id <- five_year_outlook |> select(org_id) |> distinct()
awsda_org_id <- monthly_outlook |> select(org_id) |> distinct()
cr_org_id <- actual_shortage |> select(org_id) |> distinct()
org_ids <- bind_rows(uwmp_org_id,
                     awsda_org_id,
                     cr_org_id) |> distinct()
org_id_list <- org_ids$org_id

filtered_production_delivery <- production_delivery |> 
  filter(!is.na(org_id), org_id %in% org_id_list)
actual_megatable <- full_join(actual_shortage,
                              filtered_production_delivery |> 
                                select(-water_system_name)) |> glimpse()
write_csv(actual_megatable, "data/actual_megatable.csv")

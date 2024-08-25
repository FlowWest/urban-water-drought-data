# This script attempts to join tables together as a test in usability

monthly_outlook <- read_csv("data/monthly_dry_year_outlook.csv")
five_year_outlook <- read_csv("data/five_year_outlook.csv") # forecast_start and end are annual
source_name <- read_csv("data/source_name.csv")
shortage_level <- read_csv("data/actual_water_shortage_level.csv")
production_delivery <- read_csv("data", "historical_production_delivery.csv")

# combine monthly outlook and five year outlook in a table
# I don't really like this because we just get separate rows for awsda and uwmp
glimpse(monthly_outlook)
glimpse(five_year_outlook)
forecast_megatable <- full_join(monthly_outlook |> 
                                  select(-c(reporting_interval, reporting_start_date, 
                                            reporting_end_date)),
                                five_year_outlook |> 
                                  select(-c(uwmp_year)) |> 
                                  mutate(is_annual = T))

# combine shortage level, production and delivery
# not including source name because will end up with duplicate data
glimpse(source_name)
glimpse(shortage_level)
glimpse(production_delivery)

actual_megatable <- full_join(shortage_level,
                              ear_production_delivery)

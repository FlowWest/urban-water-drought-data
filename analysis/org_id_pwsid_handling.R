# Thinking through how to join by PWSID and DWR ID and how to summarize

# data
monthly_dry_outlook <- read_csv("data/monthly_dry_year_outlook.csv")
five_year_outlook <- read_csv("data/five_year_outlook.csv")
crosswalk <- read_csv("data/id_crosswalk.csv")
source_name <- read_csv("data/source_name.csv")

## UWMP and AWSDA
dra_awsda_check <- five_year_outlook |> 
  select(org_id) |> 
  distinct() |> 
  mutate(uwmp = "data for uwmp") |> 
  full_join(monthly_dry_outlook |> 
              select(org_id) |> 
              distinct() |> 
              mutate(awsda = "data for awsda"))

# data for uwmp but not awsda: 18 org_ids
dra_awsda_check |> 
  filter(!is.na(uwmp) & is.na(awsda))
# data for awsda and not uwmp: 7 org_ids
dra_awsda_check |> 
  filter(is.na(uwmp) & !is.na(awsda))

## UWMP org_id and pwsids
# TODO We need to decide how we want to handle multiple PWSIDs: 44 with multiple PWSIDs
# TODO what about NA pwsids: 44 with NA pwsids
# We will have to aggregate data presented by pwsid

# examples -
# amador water agency, org_id == 55, 5 pwsids
# california american water company - sacramento district, org_id == 372, 11 pwsids

dra_pwsid_check <- five_year_outlook |>
  select(org_id, supplier_name) |> 
  distinct() |> 
  left_join(crosswalk |>
              select(org_id,
                     pwsid), relationship = "many-to-many")

uwmp_multiple_pwsids <- dra_pwsid_check |> 
  group_by(org_id) |> 
  tally() |> 
  filter(n > 1)

uwmp_na_pwsids <- dra_pwsid_check |> 
  filter(is.na(pwsid))

## AWSDA org_id and pwsids
# TODO We need to decide how we want to handle multiple PWSIDs: 43 with multiple PWSIDs
# TODO what about NA pwsids: 40 with NA pwsids
awsda_pwsid_check <- monthly_dry_outlook |> 
  select(org_id, supplier_name) |> 
  distinct() |> 
  left_join(crosswalk |>
              select(org_id,
                     pwsid), relationship = "many-to-many")

awsda_multiple_pwsids <- awsda_pwsid_check |> 
  group_by(org_id) |> 
  tally() |> 
  filter(n > 1)

awsda_na_pwsids <- awsda_pwsid_check |> 
  filter(is.na(pwsid))

## source name and crosswalk
# there are a lot that don't have org_id but I think that is what we expect
safer_ids <- source_name |> 
  select(pwsid) |> 
  distinct() |> 
  left_join(crosswalk |>
              select(org_id,
                     pwsid), relationship = "many-to-many")

# all missing data is happening where there isn't a pwsid
safer_uwmp <- five_year_outlook |>
  select(org_id, supplier_name) |> 
  distinct() |> 
  left_join(crosswalk |>
              select(org_id,
                     pwsid), relationship = "many-to-many") |> 
  left_join(source_name |> 
              select(pwsid) |> 
              distinct() |> 
              mutate(safer = "data for safer"))

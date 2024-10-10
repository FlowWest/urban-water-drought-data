# Making Urban Water Data Public and Useful for Understanding Drought Impacts

This repository includes code for preparing data and metadata for drought planning
and management. Below is the data management plan for maintaining this resource.

## Data Management Plan

This Data Management Plan (DMP) is for data used to understand drought impacts collected by the California Department of Water Resources (DWR) and the California State Water Resources Control Board (SWRCB). These data are collected by disparate data collection programs across DWR and SWRCB, and were compiled and processed for usability through this project. This DMP has been customized to meet the needs of this project and should be updated at least annually to accommodate additional data needs and changing objectives.

| |     |
|---------|------------|
| Project Title | Making Urban Water Data Public and Useful for Understanding Drought Impacts |
| Primary Contact | Zoe Kanavas, zoe.kanavas@water.ca.gov |
| Data Management Plan Last Updated | October 9, 2024 |
| Recommended Frequency of Update | Annual |
| Link to data | Insert when published on CNRA |

### Project Overview
The California Water Data Consortium works with the Partner Agency Team to support the implementation of the Open and Transparent Water Data Act (AB 1755). In partnership with DWR and SWRCB, the Urban Water Data Project aims to improve access to and use of urban water data in the face of critical management decisions. These data include water supply and demand information. Data needed for drought and water shortage indicators and the urban water use objectives (UWUO) were identified as priorities for publication. The project goal is to publish these data to the [California Natural Resources (CNRA) Open Data Portal](https://data.cnra.ca.gov/) for long-term maintenance. This project will serve as a proof-of-concept to establish processes and workflows that can be applied to additional datasets.

This project aims to improve the publication phase of the urban water data lifecycle for understanding drought impacts use cases, aiding drought and water scarcity management and communication. This effort helps improve policymaking, supports strong water planning, and builds trust and transparency.

### Existing Data Resources

This project makes data useful for understanding drought impacts by compiling disparate data sources, processing the data into a format useful for analyses, and providing robust metadata to ensure data can be used appropriately.

#### Urban Water Management Plan & Water Shortage Contingency Plan

##### Source Data

An urban water management plan (UWMP) is an adaptive water resources management and planning requirement for California water agencies to ensure they assess their supply reliability. The plan is intended to evaluate current and projected water supplies and demands within the urban water supplier’s service area during normal, single dry and multiple dry year periods over the next 20 to 25 years. The data within the UWMP are used to develop a standardized framework of urban water use objectives by which the state can evaluate regional water demand and water risks. Water shortage contingency plans (WSCPs) are the abridged equivalent submission requirement for small systems. These plans must contain drought-planning contacts and triggering mechanisms/levels for action.
UWMPs have both a narrative and data component. Data are submitted through tables and compliance forms provided by DWR through the [Water Use Efficiency (WUE) data portal](https://wuedata.water.ca.gov/). 

##### Quality Control

The WUEdata portal submission process includes data validation and quality-control (QC) checks, notifying the user of any errors (e.g. ensuring that all necessary fields have been completed and are within expected ranges; see Table 1 for examples). Following data validation there are three stages of QC: 

Stage 1: Primary Review

- Lead assigns plans to be reviewed as they arrive
- DWR staff reviewers use a checklist to structure their review of each UWMP/WSCP
- Checklist contains the Water Code requirements and what to look for

Stage 2: Secondary and specific reviews
Specific staff are assigned for focus topic reviews, (e.g. to check the relevant checklist items marked “Not sure” and “No”). For example, Water Shortage Contingency Plan Section staff are in charge of reviewing that part of the plan.

- SBX7-7
- WSCP 
- Energy Use 
- Other

Stage 3: Internal Determination Committee
- Meet weekly to discuss issues identified with plans not fully addressing the Water Code.
- Committee brings legal questions to Erick Soderlund when necessary
- Committee determines how to respond to the supplier regarding its UWMP. 

##### Data Access

UWMPs are updated every five years and submitted to DWR via the WUEdata portal. Data are available on the WUEdata portal and are also exported, along with data dictionaries, to the CNRA Open Data Portal. WSCPs are to be updated every five years and posted to the supplier’s website.

#### Annual Water Supply and Demand Assessment

##### Source Data

Urban water suppliers are required to submit an Annual Water Supply and Demand Assessment (AWSDA) to the California Department of Water Resource (DWR) by July 1 every year, beginning in 2022. Urban water suppliers are defined as “a water supplier, either publicly or privately owned, that directly provides potable municipal water to more than 3,000 end users or that supplies more than 3,000 acre-feet of potable water annually at retail for municipal purposes” ([AWSDA Guidance, 2022](https://wuedata.water.ca.gov/public/public_resources/3517484366/AWSDA-Final-Guidance-4-2022.pdf)). The purpose of the AWSDA is to evaluate water supply reliability for the current year and one dry year by submitting quantitative data on unconstrained demand and available supply and qualitative descriptions of the assessment methodology and each water supply source. The AWSDA is interconnected with the WSCP and UWMP (Figure 1; [AWSDA Guidance, 2022](https://wuedata.water.ca.gov/public/public_resources/3517484366/AWSDA-Final-Guidance-4-2022.pdf)).

##### Quality Control

This section is still in progress.

##### Data Access

- All data reported through the AWSDA are currently available on the [WUEdata portal](https://wuedata.water.ca.gov/wsda_export)
In the most recent [AWSDA guidance](https://wuedata.water.ca.gov/public/public_resources/3517484366/AWSDA-Final-Guidance-4-2022.pdf), see page 30-35 for information about the data elements contained in the monthly_water_shortage_outlook table. Methodology guidance is included in this report though is not implemented consistently across urban water suppliers. 
- Data are updated annually.

#### Drought and Conservation Reporting

##### Source Data

Beginning January 1, 2024, the SWRCB ordered public water systems to submit a variety of reporting requirements via SWRCB’s SAFER Clearinghouse - the system used to collect these data. These requirements, which are not requirements for all systems, include:

**Annual Inventory Report (AIR)**

- Includes drinking water source and facility inventories, drinking water flow paths, and annual drinking water supply and demand

**Monthly Drought and Conservation Report**

- Includes water shortage data for each of the three months in the reporting calendar quarter, source water data, and supply and demand data

**Urban Drought and Conservation Report**

**Monthly Potential Water Outage Report**

- Includes data concerning the water systems drinking water sources, demand, forecasted water shortages, demand reduction measures, and supply augmentation efforts

**Weekly Water Outage Report**

- Includes data concerning the water systems drinking water sources, demand, forecasted water shortages, demand reduction measures, and supply augmentation efforts

The SAFER Clearinghouse also pulls in data from other data collection programs including the Safe Drinking Water Information System (SDWIS). Some transformations are applied to the data when loading to the Clearinghouse to enhance usability (e.g. converting abbreviations to full names).

##### Quality Control

The user interface system of SAFER Clearinghouse includes validation checks. There are also flags for inconsistent information and manual reports that are generated and checked with the water system.

##### Data Access

Data are submitted via the SAFER Clearinghouse. Some of these data are accessible through the Open Data Portal, including:

- [Population data (SDWIS/Clearinghouse)](https://data.ca.gov/dataset/urban-water-use-objectives-conservation/resource/7e539a61-9a33-49e5-a5d3-463e43f0610)
- [Volumetric Annual Report of Wastewater and Recycled Water](https://data.ca.gov/dataset/volumetric-annual-report-of-wastewater-and-recycled-water)
- [Production and delivery data](https://data.ca.gov/dataset/drinking-water-public-water-system-annually-reported-water-production-and-delivery-information-2013). Though as of September 2024 this only includes in eAR data but will be updated to include Clearinghouse data.

Some data, including the facility metadata including in this data package, are not currently available. The data included in this data package were obtained by request to the SWRCB Drinking Water Division. The query used to generate those data is below and also described in the following section.

Facility data maintained in the Clearinghouse (pulled from SDWIS) can be generated using the following query:

`SELECT * FROM portal.vw_drought_reporting_data_export_SingleWaterSystem`

### Data Resources for Understanding Drought Impacts

#### Datasets

This data publication includes five datasets: (1) monthly_water_shortage_outlook, (2) five_year_water_shortage_outlook, (3) source name, (4) actual_water_shortage_level, and (5) historical_production_delivery. 

##### monthly_water_shortage_outlook

This table provides forecasted monthly (and annual) potable water shortage (or surplus) with and without shortage actions for a dry year. The Annual Water Supply and Demand Assessment (AWSDA) reports this data. All data reported through the AWSDA are available on the DWR’s [Water Use Efficiency (WUE) portal](https://wuedata.water.ca.gov/wsda_export). In the most recent [AWSDA guidance](https://wuedata.water.ca.gov/public/public_resources/3517484366/AWSDA-Final-Guidance-4-2022.pdf), see pages 30-35 for information about the data elements in the monthly_water_shortage_outlook table. Methodology guidance is included in this report, though it is not implemented consistently across urban water suppliers.  

*Data use limitations:* The primary function of the AWSDA is to motivate planning processes for water shortages. These data represent forecasts specific to the urban supplier and a snapshot in time based on the conditions when the supplier completed the plan. These data are expected to change as conditions change and water shortage plans are updated. These data can only be used within the year they are reported for, though if the forecasted water year is not dry, they are unreliable.

##### five_year_water_shortage_outlook

This table provides anticipated annual potable water levels (both surplus and shortage) with shortage actions and without shortage actions for five years based on the five driest consecutive years on record. The Urban Water Management Plans (UWMP) reports this data. All data reported through the UWMP are currently available on the [WUE portal](https://wuedata.water.ca.gov/wsda_export) and the [California Natural Resources Open Data Portal](https://data.cnra.ca.gov/dataset/2020-uwmp-data-export-tables). The most recent UWMP guidance is available [here](https://water.ca.gov/-/media/DWR-Website/Web-Pages/Programs/Water-Use-And-Efficiency/Urban-Water-Use-Efficiency/Urban-Water-Management-Plans/Final-2020-UWMP-Guidebook/UWMP-Guidebook-2020---Final-032921.pdf). See 7-20 through 7-34 for information about the data elements contained in the five_year_outlook table.

*Data use limitations:* Similar to the monthly_water_shortage_outlook data, these data also reflect forecasted values rather than actual values. These data are expected to change as conditions change.

##### source_name

This table summarizes the facility type, status, and location by public water system and facility. These data are from SDWIS and processed within the SAFER Clearinghouse. These data are assigned through facility permitting process and are not user reported, and often validated through on-the-ground field visits. The data are filtered to include the most recent data; out of date data are not included. Currently, no documentation has been published for these data.

*Data use limitations:* When using these data note that the facility name is not unique and needs to be used with the facility ID and PWSID.

##### actual_water_shortage_level

This table reports the monthly state standard shortage level by urban retail water suppliers, which are generally defined as agencies serving over 3,000 service connections or deliveries 3,000 acre-feet of water annually for municipal purposes. These data are collected by the State Water Resources Control Board through its monthly Conservation Reporting and the data included in this dataset represent a small component of the larger dataset. Information about these reports can be found on the [Water Conservation Portal](https://www.waterboards.ca.gov/water_issues/programs/conservation_portal/conservation_reporting.html), which is no longer active, and the full data (which represents the source data for this dataset) are available on the [California Open Data Portal](https://data.ca.gov/dataset/urws-conservation-supply-demand). Beginning in 2023, the reporting of these data transitioned to the SAFER Clearinghouse. 

*Data use limitations:* Prior to 2022, shortage levels were not standardized, which makes the data difficult to use. This dataset was filtered to include 2022 onwards where shortage levels are standardized. 

##### historical_production_delivery
This table provides production and delivery data by water system and water type. These data were reported through the Electronic Annual Report (eAR) and published on the [California Open Data Portal](https://data.ca.gov/dataset/drinking-water-public-water-system-annually-reported-water-production-and-delivery-information-2013). The data included in this table represent a subset of the data included in the eAR. Beginning in 2023, the reporting of these data transitioned to the SAFER Clearinghouse. The SWB is working on appending data from 2023 onwards, but this is not currently available.

*Data use limitations:* These data do not represent the most up to date production and delivery. Data from 2023 and 2024 exist but are not yet available. 

#### Data Dictionaries

- [monthly_water_shortage_outlook](https://github.com/FlowWest/urban-water-drought-data/blob/main/metadata/monthly_dry_outlook_data_dictionary.csv)
- [five_year_water_shortage_outlook](https://github.com/FlowWest/urban-water-drought-data/blob/main/metadata/five_year_outlook_data_dictionary.csv)
- [source_name](https://github.com/FlowWest/urban-water-drought-data/blob/main/metadata/source_name_data_dictionary.csv)
- [actual_water_shortage_level](https://github.com/FlowWest/urban-water-drought-data/blob/main/metadata/actual_water_shortage_level_data_dictionary.csv)
- [historical_production_delivery](https://github.com/FlowWest/urban-water-drought-data/blob/main/metadata/historical_production_delivery_data_dictionary.csv)

#### Quality Control

Quality control is expected to be handled at the source data level. There are a number of processing steps involved in preparing these datasets and QC checks are implemented to ensure the processing scripts do not include errors.

#### Data Access

Data were originally published on CNRA Open Data on (XX insert date). The data publication includes the following:

- Datasets (csv files available for download and via an API)
- Data dictionaries (csv)
- Methods
- Links to the GitHub repository used to develop the data package

#### Data Updates

The datasets included in this data package rely on data that are updated at different frequencies (see the Existing Data Resources for more information) and therefore the data updates for this package are on a similar schedule.

As of September 2024 there are pieces of this workflow that require manual tasks. The goal is to have all the underlying data published on CNRA Open Data or California Open Data and available via an API. This would then eliminate the need for manual tasks and updated to this data package could then be fully automated.

One suggested pathway for automating this workflow would be to utilize GitHub Actions. This would enable workflows to run on a schedule. The `schedule` workflow trigger would run the script that connects to the API to pull new data from Open Data, run the processing scripts, and update the package on Open Data.

The scripts that need to be run to update the data live in the [scripts](https://github.com/FlowWest/urban-water-drought-data/tree/main/scripts) folder. First run [prepare_clean_data_tables.R](https://github.com/FlowWest/urban-water-drought-data/blob/main/scripts/prepare_clean_data_tables.R). This pulls in data available via an API or data saved locally. For data saved locally, make sure you have saved the updated version and the file name and structure is correct. If there have been any changes to the data format you will need to update the data dictionaries. These live in the [metadata](https://github.com/FlowWest/urban-water-drought-data/tree/main/metadata). Note that we also considered a combined table format and that version is retained as well.

##### Steps for updating the data package

This section should be updated as more of the data pieces become available via an API. Some of the raw data elements are not saved to the repository due to size contraints. An action item would be to set up cloud-based storage through Google Drive or AWS.

**Annually**

Note that the month to do updates needs to be decided.

- The actual_water_shortage_level data are available via an API on Open Data and this could be automated. Currently this data pull and processing is in the [prepare_clean_data_tables.R](https://github.com/FlowWest/urban-water-drought-data/blob/main/scripts/prepare_clean_data_tables.R) script. If it is important to have monthly updated actual state standard shortage level data as part of the actual production delivery and shortage dataset, these data can be pulled monthly; however, as all other data will be updated annually it is not expected to be worthwhile to update these monthly.
- The historical_production_delivery data are currently updated on an unknown schedule, though this may transition to monthly. For now, assume these are updated annually. These data are not available via an API but are published on the [Open Data Portal](https://data.ca.gov/dataset/drinking-water-public-water-system-annually-reported-water-production-and-delivery-information-2013). Download the most up to date version and save to the repository in the data-raw folder. If the format changes for the data 2023-onwards it may make sense to revisit the processing. Ideally the format will stay the same and the existing code can be used in which case it may make sense to update the file name to not be 2013-2022. If the format changes and 2023-onwards are made available in a separate table from the 2013-2022 additional processing code will need to be added.
- monthly_water_shortage_outlook data from the AWSDA data are updated annually in July. These data are currently available on the WUE portal and require manual download. Visit the [WUE portal](https://wuedata.water.ca.gov/wsda_export) and download the most recent year. The tables needed are Table 1 and Table 4. Save these to the repository in a data-raw folder. Updated data will likely exist as an excel with the most up to date year, not appended to previous years. This will require updates to the processing but should be similar to what is currently applied. 
- If it is important to have monthly updated information for the source name table, these data can be updated monthly. These data are not available via an API and to update these data would require contacting the Division of Drinking Water (current point of contact is Eric Zuniga, eric.zuniga@waterboards.ca.gov). The following query would need to be run and exported. The exported file would then be uploaded to the repository (currently saved as `data-raw/20240509_SAFER_CLEARINGHOUSE_EXPORT - WDC.xlsx` though due to the large size not saved to GitHub). When running the processing scripts make sure the file name and structure is correct and update as needed.

**Every five years**

Note that the month to do updates needs to be decided.

The five_year_water_shortage_outlook data using UWMP data are updated every five years. These data are available on the [WUE portal](https://wuedata.water.ca.gov/wsda_export) and may also be available on CNRA Open Data portal. Table 7-5 is needed and can downloaded and saved to adata-raw folder. Similar to the AWSDA, the most up to date data are likely stored separately and updates to the processing script would need to be made.
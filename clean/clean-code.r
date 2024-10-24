##  Install libraries
library(tidyverse)
library(units)
library(Rcpp)
library(tmap)
library(sf)
library(dplyr)
library(plyr)
library(readr)

## Import data from multiple csv. files at once
mydir = "NorthEast1" # Set directory as folder with all csv in
myfiles = list.files(path=mydir, pattern="*.csv", full.names=TRUE) # Create list of csv file names 
dat_csv_NorthEast = ldply(myfiles, read_csv) # Read in all csv files in the list
write.csv(dat_csv_NorthEast, "NorthEast_EPC_UPRN.csv") 

## Import boundary data
NorthEast_OA <- st_read("NorthEast_OA.gpkg") # Read OA shapefile
NorthEast_LAD <- st_read("NorthEast_LAD.gpkg") # Read LAD shapefile
NorthEast_UPRN <- st_read("NorthEast_UPRN.gpkg") # Read LCR UPRN shapefile
NorthEast_UPRN$UPRN <- as.character(NorthEast_UPRN$UPRN) # Convert UPRN to character

UPRN_XY_NorthEast <- st_write(NorthEast_UPRN, "UPRN_NorthEast_XY.csv", 
                    layer_options = "GEOMETRY=AS_XY") # Convert UPRN gpkg into a csv. with xy coordinates
                    
UPRN_XY_NorthEast$UPRN <- as.character(UPRN_XY_NorthEast$UPRN)
dat_csv_NorthEast$UPRN <- as.character(dat_csv_NorthEast$UPRN)

## Joing EPC to UPRN
UPRN_EPC_XY_NorthEast <- dat_csv_NorthEast %>% 
  left_join(UPRN_XY_NorthEast, by ="UPRN") # Join two tables together so that all properties with EPC rating have a xy coordinate

## Filter a single EPC for private rentals only from the UPRN dataset
target <- c("rental (private)", "Rented (private)") # Create new object with two categories for PRS

NorthEast_EPC_PRS <- UPRN_EPC_XY_NorthEast %>% # Filter private rentals from the EPC dataset
  filter(TENURE %in% target)

NorthEast_EPC_PRS$ADDRESS_COMBINED <- paste(NorthEast_EPC_PRS$ADDRESS1, 
                                    NorthEast_EPC_PRS$ADDRESS2, 
                                    NorthEast_EPC_PRS$ADDRESS3)

NorthEast_EPC_PRS_REC <- NorthEast_EPC_PRS %>% group_by(ADDRESS_COMBINED) %>%
  slice(which.max(as.Date(INSPECTION_DATE, '%d/%m/%y')))

NorthEast_EPC_PRS_RECENT <- NorthEast_EPC_PRS_REC %>%
  filter(INSPECTION_DATE > '01/09/2012')

## Write as new gpkg
st_write(NorthEast_EPC_PRS_RECENT, "NorthEast_EPC_PRS_UPRN.gpkg") # Write full dataset

## Calculate new variables
NorthEast_EPC_PRS_RECENT <- st_as_sf(NorthEast_EPC_PRS_RECENT) 

NorthEast_EPC_PRS_OA <- NorthEast_OA %>% 
  st_join(NorthEast_EPC_PRS_RECENT) %>%
  group_by(OA21CD) %>%
  dplyr::summarize(LOCAL_AUTHORITY = first(LOCAL_AUTHORITY), # Returns the first elements, i.e. the LA code in this case
                  count_EPC = n(),# Count number of EPC ratings for PRS properties in each OA
                   count_current_D = sum(CURRENT_ENERGY_RATING == "D"),
                   count_current_E = sum(CURRENT_ENERGY_RATING == "E"),
                   count_current_F = sum(CURRENT_ENERGY_RATING == "F"),
                   count_current_G = sum(CURRENT_ENERGY_RATING == "G"),
                   count_potential_D = sum(POTENTIAL_ENERGY_RATING == "D"),
                   count_potential_E = sum(POTENTIAL_ENERGY_RATING == "E"),
                   count_potential_F = sum(POTENTIAL_ENERGY_RATING == "F"),
                   count_potential_G = sum(POTENTIAL_ENERGY_RATING == "G"),
                  count_terrace_end = sum(BUILT_FORM == "End-Terrace"),
                  count_terrace_enclosedend = sum(BUILT_FORM == "End-Terrace Enclosed"),
                  count_terrace_mid = sum(BUILT_FORM == "Mid-Terrace"),
                  count_terrace_enclosedmid = sum(BUILT_FORM == "Enclosed Mid-Terrace"),
                  count_semidetached = sum(BUILT_FORM == "Semi-Detached"),
                  count_detached = sum(BUILT_FORM == "Detached"),
                  count_house = sum(PROPERTY_TYPE == "House"),
                  count_bungalow = sum(PROPERTY_TYPE == "Bungalow"),
                  count_flat = sum(PROPERTY_TYPE == "Flat"),
                  count_maisonette = sum(PROPERTY_TYPE == "Maisonette"),
                  count_parkhome = sum(PROPERTY_TYPE == "Park home"),
                  count_mainsgas = sum(MAINS_GAS_FLAG == "N"),
                  count_pre1900 = sum(CONSTRUCTION_AGE_BAND == "England and Wales: before 1900"),
                  count_since2012 = sum(CONSTRUCTION_AGE_BAND == "England and Wales: 2012 onwards"),
                  count_hotwaterpoor = sum(HOT_WATER_ENERGY_EFF == "Poor"),
                  count_hotwaterverypoor = sum(HOT_WATER_ENERGY_EFF == "Very Poor"),
                  count_wallspoor = sum(WALLS_ENERGY_EFF == "Poor"),
                  count_wallsverypoor = sum(WALLS_ENERGY_EFF == "Very Poor"),
                  count_mainheatpoor = sum(MAINHEAT_ENV_EFF == "Poor"),
                  count_mainheatverypoor = sum(MAINHEAT_ENV_EFF == "Very Poor"))
                  
NorthEast_EPC_PRS_OA$count_current_D <- as.numeric(NorthEast_EPC_PRS_OA$count_current_D)
NorthEast_EPC_PRS_OA$count_current_E <- as.numeric(NorthEast_EPC_PRS_OA$count_current_E)
NorthEast_EPC_PRS_OA$count_current_F <- as.numeric(NorthEast_EPC_PRS_OA$count_current_F)
NorthEast_EPC_PRS_OA$count_current_G <- as.numeric(NorthEast_EPC_PRS_OA$count_current_G)
NorthEast_EPC_PRS_OA$count_potential_D <- as.numeric(NorthEast_EPC_PRS_OA$count_potential_D)
NorthEast_EPC_PRS_OA$count_potential_E <- as.numeric(NorthEast_EPC_PRS_OA$count_potential_E)
NorthEast_EPC_PRS_OA$count_potential_F <- as.numeric(NorthEast_EPC_PRS_OA$count_potential_F)
NorthEast_EPC_PRS_OA$count_potential_G <- as.numeric(NorthEast_EPC_PRS_OA$count_potential_G)
NorthEast_EPC_PRS_OA$count_terrace_end <- as.numeric(NorthEast_EPC_PRS_OA$count_terrace_end)
NorthEast_EPC_PRS_OA$count_terrace_mid <- as.numeric(NorthEast_EPC_PRS_OA$count_terrace_mid)
NorthEast_EPC_PRS_OA$count_terrace_enclosedend <- as.numeric(NorthEast_EPC_PRS_OA$count_terrace_enclosedend)
NorthEast_EPC_PRS_OA$count_terrace_enclosedmid <- as.numeric(NorthEast_EPC_PRS_OA$count_terrace_enclosedmid)
NorthEast_EPC_PRS_OA$count_semidetached <- as.numeric(NorthEast_EPC_PRS_OA$count_semidetached)
NorthEast_EPC_PRS_OA$count_detached <- as.numeric(NorthEast_EPC_PRS_OA$count_detached)
NorthEast_EPC_PRS_OA$count_house <- as.numeric(NorthEast_EPC_PRS_OA$count_house)
NorthEast_EPC_PRS_OA$count_bungalow <- as.numeric(NorthEast_EPC_PRS_OA$count_bungalow)
NorthEast_EPC_PRS_OA$count_flat <- as.numeric(NorthEast_EPC_PRS_OA$count_flat)
NorthEast_EPC_PRS_OA$count_maisonette <- as.numeric(NorthEast_EPC_PRS_OA$count_maisonette)
NorthEast_EPC_PRS_OA$count_parkhome <- as.numeric(NorthEast_EPC_PRS_OA$count_parkhome)
NorthEast_EPC_PRS_OA$count_mainsgas <- as.numeric(NorthEast_EPC_PRS_OA$count_mainsgas)
NorthEast_EPC_PRS_OA$count_pre1900 <- as.numeric(NorthEast_EPC_PRS_OA$count_pre1900)
NorthEast_EPC_PRS_OA$count_since2012 <- as.numeric(NorthEast_EPC_PRS_OA$count_since2012)
NorthEast_EPC_PRS_OA$count_hotwaterpoor <- as.numeric(NorthEast_EPC_PRS_OA$count_hotwaterpoor)
NorthEast_EPC_PRS_OA$count_hotwaterverypoor <- as.numeric(NorthEast_EPC_PRS_OA$count_hotwaterverypoor)
NorthEast_EPC_PRS_OA$count_wallspoor <- as.numeric(NorthEast_EPC_PRS_OA$count_wallspoor)
NorthEast_EPC_PRS_OA$count_wallsverypoor <- as.numeric(NorthEast_EPC_PRS_OA$count_wallsverypoor)
NorthEast_EPC_PRS_OA$count_mainheatpoor <- as.numeric(NorthEast_EPC_PRS_OA$count_mainheatpoor)
NorthEast_EPC_PRS_OA$count_mainheatverypoor <- as.numeric(NorthEast_EPC_PRS_OA$count_mainheatverypoor)

NorthEast_EPC_PRS_OA_Combined <- NorthEast_EPC_PRS_OA %>%
  mutate(count_current_DandBelow = count_current_D + count_current_E 
                                  + count_current_F + count_current_G,
         count_potential_DandBelow = count_potential_D + count_potential_E
                                     + count_potential_F + count_potential_G,
         count_current_FandBelow = count_current_F + count_current_G,
         count_potential_FandBelow = count_potential_F + count_potential_G,
         count_allterrace = count_terrace_end + count_terrace_enclosedend + 
                        count_terrace_mid + count_terrace_enclosedmid,
         count_housebungalow = count_house + count_bungalow,
         count_flatmaisonette = count_flat + count_maisonette,
         count_hotwaterall = count_hotwaterpoor + count_hotwaterverypoor,
         count_wallsall = count_wallspoor + count_wallsverypoor,
         count_mainsheatall = count_mainheatpoor + count_mainheatverypoor)

NorthEast_EPC_PRS_OA_Combined$count_current_DandBelow[is.na(NorthEast_EPC_PRS_OA_Combined$count_current_DandBelow)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_potential_DandBelow[is.na(NorthEast_EPC_PRS_OA_Combined$count_potential_DandBelow)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_current_FandBelow[is.na(NorthEast_EPC_PRS_OA_Combined$count_current_FandBelow)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_potential_FandBelow[is.na(NorthEast_EPC_PRS_OA_Combined$count_potential_FandBelow)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_allterrace[is.na(NorthEast_EPC_PRS_OA_Combined$count_allterrace)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_housebungalow[is.na(NorthEast_EPC_PRS_OA_Combined$count_housebungalow)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_flatmaisonette[is.na(NorthEast_EPC_PRS_OA_Combined$count_flatmaisonette)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_hotwaterall[is.na(NorthEast_EPC_PRS_OA_Combined$count_hotwaterall)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_mainsheatall[is.na(NorthEast_EPC_PRS_OA_Combined$count_mainsheatall)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_pre1900[is.na(NorthEast_EPC_PRS_OA_Combined$count_pre1900)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_since2012[is.na(NorthEast_EPC_PRS_OA_Combined$count_since2012)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_parkhome[is.na(NorthEast_EPC_PRS_OA_Combined$count_parkhome)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_semidetached[is.na(NorthEast_EPC_PRS_OA_Combined$count_semidetached)] <- 0
NorthEast_EPC_PRS_OA_Combined$count_detached[is.na(NorthEast_EPC_PRS_OA_Combined$count_detached)] <- 0

## Export dataset
NorthEast_EPC_PRS_OA_Combined_SF <-sf::st_make_valid(NorthEast_EPC_PRS_OA_Combined)
st_write(NorthEast_EPC_PRS_OA_Combined_SF, "NorthEast_EPC_PRS_OA_counts.gpkg") # Write full dataset

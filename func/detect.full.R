#############################################################################
###"func/detect.full.R"
## This script does:
# 1. Run make_whole() on a time series to prep for event detection
# 2. Run detect()
# 3. Return event or annual results
## DEPENDS ON:
# (dat) must have a "site" = site, "t" = date, "temp" = temperature columns
# The function will attempt to correct if these are missing
# It will tell you what is missing if so
## USED BY:
# "2.Model_fitting.R"
## CREATES:
# MHW results
#############################################################################

library(RmarineHeatWaves)

## For testing purposes
# load("data/SACTN/SACTN_cropped.Rdata")
# dat <- SACTN_cropped[SACTN_cropped$site == levels(SACTN_cropped$site)[4],]
# start <- year(dat$date[1])+1
# end <- year(dat$date[nrow(dat)])-1
# pctile <- 90
# dur <- 5
# gap <- 2
# cold_spell <- TRUE

#  ------------------------------------------------------------------------
## This function must be given site = site, t = time and temp = temperature columns, same as make_whole
## It then does all of the necessary calculations dynamically for the time series given
## This is done so it can be run in a for loop
## Dplyr would be ideal but the output of detect() complicates this
detect.full <- function(dat, start, end, dur, gap, cold_spell){
  col.index <- c("site", "t", "temp")
  colnames(dat)[colnames(dat) == "date"] <- "t"
  dat <- dat[colnames(dat) %in% col.index]
  if(ncol(dat) < 3){
    stop(paste("Your data.frame is missing", colnames(dat[!(colnames(dat) %in% col.index)]), sep = " "))
  }
  site <- as.character(dat$site[1])
  dat2 <- dat
  dat2$site <- NULL
  whole <- make_whole(dat2)
  results <- detect(whole, climatology_start = start, climatology_end = end,
                  min_duration = dur, max_gap = gap, cold_spells = cold_spell)
  results$clim$site <- site
  results$event$site <- site
  return(results)
}


#  ------------------------------------------------------------------------
## This function is designed to be used with step 2 in "2.Model_fitting.R"

# dat <- SACTN_cropped[SACTN_cropped$site == levels(SACTN_cropped$site)[5],]

detect.SACTN <- function(dat){
  site <- as.character(dat$site[1])
  start <- dat$start[1]
  end <- dat$end[1]
  dat <- dat[,2:3]
  whole <- make_whole(dat)
  # MHW
  mhw <- RmarineHeatWaves::detect(whole, climatology_start = start, climatology_end = end,
                    min_duration = 5, max_gap = 2, cold_spells = FALSE)
  mhw$event$type <- "MHW"
  mhw$event$site <- site
  mhw$clim$type <- "MHW"
  mhw$clim$site <- site
  # mhw <- mhw$event
  # mhw$type <- "MHW"
  # mhw$site <- site
  # Combine
  event <- data.frame(mhw$event)
  clim <- data.frame(mhw$clim)
  res <- list(event = event, clim =  clim)
  return(res)
}

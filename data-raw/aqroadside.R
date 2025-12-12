## code to prepare `aqroadside` dataset goes here

library(openair)
library(worldmet)
library(dplyr)
library(mirai)

daemons(4)

# import AQ data
aqroadside <- importUKAQ(
  site = "my1",
  year = 2000:2016,
  hc = TRUE
)

# import met data
met <- importNOAA(year = 2000:2016, source = "fwf")

# join together but ignore met data in aqroadside because it is modelled
aqroadside <-
  left_join(select(aqroadside, -ws, -wd, -air_temp), met, by = "date")

aqroadside <- select(
  aqroadside,
  date,
  nox,
  no2,
  ethane,
  isoprene,
  benzene,
  ws,
  wd,
  air_temp,
  RH,
  cl
)

aqroadside <- tibble(aqroadside)

usethis::use_data(aqroadside, overwrite = TRUE)

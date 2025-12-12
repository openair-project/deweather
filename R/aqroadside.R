#' Example air quality monitoring data for openair
#'
#' \describe{
#' \item{date}{Observation date/time stamp in year-month-day hour:minute:second
#' format (POSIXct).}
#' \item{ws}{Wind speed, in m/s, as numeric vector.}
#' \item{wd}{Wind direction, in degrees from North, as a numeric vector.}
#' \item{nox}{Oxides of nitrogen concentration, in ppb, as a numeric vector.}
#' \item{no2}{Nitrogen dioxide concentration, in ppb, as a numeric vector.}
#' \item{o3}{Ozone concentration, in ppb, as a numeric vector.}
#' \item{pm10}{Particulate PM10 fraction measurement, in ug/m3 (raw TEOM), as a
#' numeric vector.}
#' \item{so2}{Sulfur dioxide concentration, in ppb, as a numeric vector.}
#' \item{co}{Carbon monoxide concentration, in ppm, as a numeric vector.}
#' \item{pm25}{Particulate PM2.5 fraction measurement, in ug/m3, as a numeric
#' vector.}
#' }
#'
#' @examples
#' # basic structure
#' head(aqroadside)
"aqroadside"

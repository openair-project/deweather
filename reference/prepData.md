# Function to prepare data frame for modelling

This function takes a data frame that contains a field `date` and other
variables and adds other common variables needed by the modelling
functions. This function is run automatically by
[`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
but can be used separately for further analysis. These variables
include:

- **hour** - The hour of the day from 0 to 23.

- **hour.local** - The hour in the local time zone. Note that the local
  time zone will need to be supplied (see `local.tz`). The purpose of
  using local time rather than UTC is that emissions can vary more
  strongly by local time rather than UTC.

- **weekday** - The day of the week.

- **trend** - The trend is calculated as a decimal year.

- **week** - The week of the year. Useful for taking account of
  long-term seasonal variations.

- **jday** - The Julian Day number.

- **month** - month of the year. Useful for taking account of long-term
  seasonal variations.

## Usage

``` r
prepData(
  mydata,
  add = c("hour", "hour.local", "weekday", "trend", "week", "jday", "month"),
  local.tz = "Europe/London",
  lag = NULL
)
```

## Arguments

- mydata:

  A data frame to process.

- add:

  Names of explanatory variables to include.

- local.tz:

  Used if hour needs to be expressed in local time. This can be useful
  for situations where the anthropogenic emissions source is strong and
  follows local time rather than UTC.

- lag:

  Variables(s) to lag. Any variables included here will add new columns
  to the data frame. For example `lag = "ws"` with add a new columns
  `lag1ws`. Adding some variables here can improve the explanatory power
  of the models. Variables are lagged by one unit of time.

## Value

A data frame with new variables.

## Author

David Carslaw

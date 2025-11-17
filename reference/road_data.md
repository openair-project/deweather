# Example data for deweather

The `road_data` dataset is provided as an example dataset as part of the
`deweather` package. The dataset contains hourly measurements of air
pollutant concentrations, wind speed and wind direction collected at the
Marylebone (London) air quality monitoring supersite between 1st January
1998 and 23rd June 2005.

## Usage

``` r
road_data
```

## Format

Data frame with 65533 observations (rows) and the following 10
variables:

- date:

  Observation date/time stamp in year-month-day hour:minute:second
  format (POSIXct).

- ws:

  Wind speed, in m/s, as numeric vector.

- wd:

  Wind direction, in degrees from North, as a numeric vector.

- nox:

  Oxides of nitrogen concentration, in ppb, as a numeric vector.

- no2:

  Nitrogen dioxide concentration, in ppb, as a numeric vector.

- o3:

  Ozone concentration, in ppb, as a numeric vector.

- pm10:

  Particulate PM10 fraction measurement, in ug/m3 (raw TEOM), as a
  numeric vector.

- so2:

  Sulfur dioxide concentration, in ppb, as a numeric vector.

- co:

  Carbon monoxide concentration, in ppm, as a numeric vector.

- pm25:

  Particulate PM2.5 fraction measurement, in ug/m3, as a numeric vector.

## Examples

``` r
# basic structure
head(road_data)
#> # A tibble: 6 × 11
#>   date                  nox   no2 ethane isoprene benzene    ws    wd air_temp
#>   <dttm>              <dbl> <dbl>  <dbl>    <dbl>   <dbl> <dbl> <dbl>    <dbl>
#> 1 1998-01-01 00:00:00   546    74     NA       NA      NA   1     280     3.6 
#> 2 1998-01-01 01:00:00    NA    NA     NA       NA      NA   1     230     3.5 
#> 3 1998-01-01 02:00:00    NA    NA     NA       NA      NA   1.5   180     4.25
#> 4 1998-01-01 03:00:00   944    99     NA       NA      NA  NA      NA    NA   
#> 5 1998-01-01 04:00:00   894   149     NA       NA      NA   1.5   180     3.8 
#> 6 1998-01-01 05:00:00   506    80     NA       NA      NA   1     190     3.5 
#> # ℹ 2 more variables: RH <dbl>, cl <dbl>
```

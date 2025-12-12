# Example air quality monitoring data for openair

`aqroadside` represents a subset of long-running hourly data from the
Marylebone Road AURN roadside monitoring station in the UK, bound with
meteorological data from the nearby Heathrow airport met station. Five
pollutants (NOx, NO2, Ethane, Isoprene and Benzene) and five
meteorlogical variables (wind speed, wind direction, air temperature,
relative humidity, and cloud height) are provided.

## Usage

``` r
aqroadside
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with
149040 rows and 11 columns.

## Examples

``` r
# basic structure
head(aqroadside)
#> # A tibble: 6 × 11
#>   date                  nox   no2 ethane isoprene benzene    ws    wd air_temp
#>   <dttm>              <dbl> <dbl>  <dbl>    <dbl>   <dbl> <dbl> <dbl>    <dbl>
#> 1 2000-01-01 00:00:00   388    78   13.5     1.22    7.74  2.1    200     7.4 
#> 2 2000-01-01 01:00:00   886    84   12.0     0.85    5.66  2.1    190     7.83
#> 3 2000-01-01 02:00:00   816   117   14.7     1.75   11.4   1.8    215     7.95
#> 4 2000-01-01 03:00:00   636    97   20.4     4.36   30.8   1.25   240     8.05
#> 5 2000-01-01 04:00:00   483    74   18.8     3.08   19.7   1.55   260     8.6 
#> 6 2000-01-01 05:00:00   231    65   16.4     2.12   13.1   2.35   270     8.35
#> # ℹ 2 more variables: rh <dbl>, cl <dbl>
```

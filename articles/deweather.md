# Meteorological Normalisation with {deweather}

``` r
library(deweather)
```

## Introduction

Meteorology plays a central role in affecting the concentrations of
pollutants in the atmosphere. When considering trends in air pollutants
it can be very difficult to know whether a change in concentration is
due to emissions or meteorology.

The **deweather** package uses a powerful statistical technique based on
*boosted regression trees* using the
[gbm](https://github.com/gbm-developers/gbm) package [¹](#fn1).
Statistical models are developed to explain concentrations using
meteorological and other variables. These models can be tested on
randomly withheld data with the aim of developing the most appropriate
model.

## Example data set

The **deweather** package comes with a comprehensive data set of air
quality and meteorological data. The air quality data is from Marylebone
Road in central London (obtained from the
[openair](https://openair-project.github.io/openair/) package) and the
meteorological data from Heathrow Airport (obtained from the
[worldmet](https://openair-project.github.io/worldmet/) package).

The `road_data` data frame contains various pollutants such a NO_(x),
NO₂, ethane and isoprene as well as meteorological data including wind
speed, wind direction, relative humidity, ambient temperature and cloud
cover. Code to obtain this data directly can be found
[here](https://github.com/openair-project/deweather/blob/master/data-raw/road_data.R).

``` r
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

To speed up the examples in this article we’ll randomly sample some of
`road_data`.

## Construct and test model(s)

The
[`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md)
function is used to build and test various models to help derive the
most appropriate.

In this example, we will restrict the data to model to 4 years. Note
that variables such as `"hour"` and `"weekday"` are used as variables
that can be used to explain some of the variation. `"hour"` for example
very usefully acts as a proxy for the diurnal variation in emissions.
These temporal emission proxies are also important to include to help
the model differentiate between emission versus weather-related changes.
For example, emissions tend to change throughout a day and so do
variables such as wind speed and ambient temperature.

``` r
library(openair)
# select only part of the data set
dat_part <- selectByDate(road_data, year = 2001:2004)

# to speed up the example, sample rows in `dat_part`
# not needed in reality
dat_part <- dplyr::slice_sample(dat_part, prop = 1 / 10)

# test a model with commonly used covariates
mod_test <-
  testMod(
    dat_part,
    vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp", "week"),
    pollutant = "no2"
  )
#> ℹ Optimum number of trees is 398
#> ℹ RMSE from cross-validation is 23.59
#> ℹ Percent increase in RMSE using test data is 28.0%
```

![A scatter plot showing predicted nitrogen dioxide on the x-axis and
measured nitrogen dioxide on the y-axis. Alongside is a table of
statistical values describing the model performance, including R, RMSE,
NMGE, NMB, MGE, MB, FAC2 and
n.](deweather_files/figure-html/testMod-1.png)

A statistical summary of a
[deweather](https://openair-project.github.io/deweather/) model test.

The output shows by default the performance of the model when applied to
a withheld random 20% (by default) of the data, i.e., the model is
evaluated against data not used to build the model. Common model
evaluation metrics are also given.

## Build a model

Assuming that a good model can be developed, it can now be explored in
more detail using the optimum number of trees from
[`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md).

``` r
mod_no2 <- buildMod(
  dat_part,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp", "week"),
  pollutant = "no2",
  n.trees = mod_test$optimum_trees,
  n.core = 6
)
```

This function returns a `deweather` object that can be interrogated as
shown below.

## Examine the partial dependencies

### Plot all partial dependencies

One of the benefits of the boosted regression tree approach is that the
*partial dependencies* can be explored. In simple terms, the partial
dependencies show the relationship between the pollutant of interest and
the covariates used in the model while holding the value of other
covariates at their mean level.

``` r
plotPD(mod_no2, nrow = 4)
#> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` instead.
#> ℹ The deprecated feature was likely used in the deweather package.
#>   Please report the issue at
#>   <https://github.com/openair-project/deweather/issues>.
#> This warning is displayed once every 8 hours.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.
```

![Seven line charts showing the partial dependencies of the deweather
model. In order of influence: wind direction, hour of day, long-term
trend, weekday, wind speed, week of the year, and finally air
temperature.](deweather_files/figure-html/plotAll-1.png)

The 7 partial dependencies of the deweather model.

### Plot two-way interactions

It can be very useful to plot important two-way interactions. In this
example the interaction between `"ws"` and `"air_temp"` is considered.
The plot shows that NO₂ tends to be high when the wind speed is low and
the temperature is low, i.e., stable atmospheric conditions. Also NO₂
tends to be high when the temperature is high, which is most likely due
to more O₃ available to convert NO to NO₂. In fact, background O₃ would
probably be a useful covariate to add to the model.

``` r
plot2Way(mod_no2, variable = c("ws", "air_temp"))
```

![A heatmap showing the interaction between air temperature and wind
speed in the deweather model. Nitrogen dioixde is shown to be high when
wind speed is low and temperature is either very low or above around 25
degrees Celcius.](deweather_files/figure-html/plot2way-1.png)

A two-way interaction plot showing the interaction between wind speed
and air temperature

## Apply meteorological averaging

An *indication* of the meteorologically-averaged trend is given by the
[`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
function above, and can even be isolated using the `variable` argument.

``` r
plotPD(mod_no2, variable = "trend")
```

![Patial dependence plot of the 'trend' component of the deweather model
with date on the x-axis and NO2 on the y-axis. The trend is jagged, but
shows an increase in 2003.](deweather_files/figure-html/pd-trend-1.png)

The partial dependence plot of the ‘trend’ component.

A much better indication is given by using the model to predict many
times with random sampling of **meteorological** conditions. This
sampling is carried out by the
[`metSim()`](https://openair-project.github.io/deweather/reference/metSim.md)
function. Note that in this case there is no need to supply the
`"trend"` component because it is calculated using
[`metSim()`](https://openair-project.github.io/deweather/reference/metSim.md).

``` r
demet <- metSim(mod_no2,
  newdata = dat_part,
  metVars = c("ws", "wd", "air_temp")
)
```

Now it is possible to plot the resulting trend.

``` r
openair::timePlot(demet, "no2", ylab = "Deweathered no2 (ug/m3)")
```

![A line chart with date on the x-axis and deweathered NO2 on the
y-axis. The trend is very noisy, but shows an increase in concentrations
in 2003.](deweather_files/figure-html/plotTrend-1.png)

A deweathered nitrogen dioxide trend.

The plot shows the trend in NO₂ controlling for the main weather
variables. The plot now reveals the strong diurnal and weekly cycle in
NO₂ that is driven by variations in the sources of NO₂ (NO_(x)) rather
than meteorology i.e. road traffic which has strong hourly and daily
variations throughout the year. It can be useful to simply average the
results to provide a better indication of the overall trend. For
example:

``` r
openair::timePlot(demet, "no2", avg.time = "week", ylab = "Deweathered no2 (ug/m3)")
```

![A line chart with date on the x-axis and deweathered NO2 on the
y-axis. The trend has been time averaged to show weekly mean
concentrations, clearly illustrating a sharp increase in
2003.](deweather_files/figure-html/plotTrendAve-1.png)

A time-averaged deweathered nitrogen dioxide trend.

------------------------------------------------------------------------

1.  Ridgeway G, Developers G (2024). *gbm: Generalized Boosted
    Regression Models*. R package version 2.2.2,
    <https://CRAN.R-project.org/package=gbm>

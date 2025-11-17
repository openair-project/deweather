# Changelog

## deweather (development version)

### New Features

- The plot assemblies in
  [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
  and
  [`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md)
  are now powered by [patchwork](https://patchwork.data-imaginist.com).
  This will allow for more post-hoc control of the plot assembly using
  `&` for example.

- Users can now select their parallelisation type in
  [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
  ([@djg46](https://github.com/djg46)).

- Added `n.core` arguments to `runGbm()` and
  [`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md),
  which are passed to
  [`gbm::gbm()`](https://rdrr.io/pkg/gbm/man/gbm.html). This may improve
  function performance ([@djg46](https://github.com/djg46)).

### Bug fixes

- Fixed an issue where
  [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
  would fail if there wasn’t a character variable (e.g., “weekday”).

- Added `ylab` back as an explicit option for
  [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md).

- [`prepData()`](https://openair-project.github.io/deweather/reference/prepData.md)
  will now formally error if `mydata$date` is numeric/character/factor
  (i.e., not a date/datetime).

- Fixed a bug where
  [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
  would work differently if the input to
  [`buildMod()`](https://openair-project.github.io/deweather/reference/buildMod.md)
  was a `data.frame` rather than a `tibble`.

## deweather 0.7.2

### Breaking changes

- All functions which expect a
  [deweather](https://openair-project.github.io/deweather/) object now
  use the argument name `dw_model` for consistency.

- The default values for `vars` in any model-building function now uses
  “air_temp” over “temp”. This brings it in line with `road_data` and
  [worldmet](https://openair-project.github.io/worldmet/) outputs.

- `gbm.interactions()` has been renamed
  [`gbmInteractions()`](https://openair-project.github.io/deweather/reference/gbmInteractions.md)
  for consistency with other functions.

- `gbmInf()` has been renamed
  [`plotInfluence()`](https://openair-project.github.io/deweather/reference/plotInfluence.md)
  to be more descriptive and consistent with other plotting functions.

- `plotAllPD()` has been combined with
  [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
  and has therefore been removed.

- `dat` is no longer exported. Users should use `road_data` to demo
  [deweather](https://openair-project.github.io/deweather/) functions.

### New features

- [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
  now holds all the functionality for plotting partial dependency plots,
  deprecating `plotAllPD()`.
  ([\#12](https://github.com/openair-project/deweather/issues/12))

  - By default, all partial dependencies are plotted (similar to
    `plotAllPD()`). The `variable` argument allows users to specify
    specific variables (similar to the old
    [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)).
    Multiple variables can be provided.

  - The `col` argument controls the colour of the PD plots. If multiple
    colours are specified, they are repeated until all variables have
    been visualised.

  - The `polar.wd` argument will optionally show the wind direction PD
    on polar coordinates.

- [`plotInfluence()`](https://openair-project.github.io/deweather/reference/plotInfluence.md)
  (previously `gmbInf()`) has gained two new arguments:

  - `sort` (defaults to `TRUE`) will sort the variables by their mean
    influence, ordering the values on the y-axis.

  - `col` controls the colours. Users can specify `var` (which makes
    each bar a different colour) or `mean` (which colours by the x-axis
    values).

- Many plotting functions have received the `plot` argument to suppress
  printing their plots, bringing
  [deweather](https://openair-project.github.io/deweather/) in line with
  recent versions of
  [openair](https://openair-project.github.io/openair/).

- [`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md)
  invisibly returns its table of statistics along with its plot.
  ([\#9](https://github.com/openair-project/deweather/issues/9))

- [`testMod()`](https://openair-project.github.io/deweather/reference/testMod.md)
  now prints one plot and one table rather than one plot and two tables.
  This ensures the printed plot will be less distorted.

- The lists returned by
  [`plotPD()`](https://openair-project.github.io/deweather/reference/plotPD.md)
  are now named, making them easier to index.
  ([\#10](https://github.com/openair-project/deweather/issues/10))

- [deweather](https://openair-project.github.io/deweather/) model
  objects now have nicer [`print()`](https://rdrr.io/r/base/print.html),
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html),
  [`head()`](https://rdrr.io/r/utils/head.html),
  [`tail()`](https://rdrr.io/r/utils/head.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) methods.

### Bug fixes

- [`diurnalGbm()`](https://openair-project.github.io/deweather/reference/diurnalGbm.md)
  now no longer plots extra 2-way graphs as it performs its internal
  calculations.

## deweather 0.7-1

- First development version of
  [deweather](https://openair-project.github.io/deweather/).

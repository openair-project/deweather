![](reference/figures/logo.png)

## **deweather**

### open source tools to remove meteorological variation from air quality data

**deweather** is an R package developed for the purpose of “removing”
the influence of meteorology from air quality time series data. The
package uses a *boosted regression tree* approach for modelling air
quality data. These and similar techniques provide powerful tools for
building statistical models of air quality data. They are able to take
account of the many complex interactions between variables as well as
non-linear relationships between the variables.

*Part of the openair toolkit*

[![openair](https://img.shields.io/badge/openair_core-06D6A0?style=flat-square)](https://openair-project.github.io/openair/)
\|
[![worldmet](https://img.shields.io/badge/worldmet-26547C?style=flat-square)](https://openair-project.github.io/worldmet/)
\|
[![openairmaps](https://img.shields.io/badge/openairmaps-FFD166?style=flat-square)](https://openair-project.github.io/openairmaps/)
\|
[![deweather](https://img.shields.io/badge/deweather-EF476F?style=flat-square)](https://openair-project.github.io/deweather/)

------------------------------------------------------------------------

## 💡 Core Features

**deweather** makes it straightforward to test, build, and evaluate
models in R.

- **Test and build meteorological normalisation models** flexibly using
  [`tune_dw_model()`](https://openair-project.github.io/deweather/reference/tune_dw_model.md)
  and
  [`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

- **Plot and examine models** in a myriad of ways, including visualising
  partial dependencies, using functions like
  [`plot_dw_importance()`](https://openair-project.github.io/deweather/reference/plot_dw_importance.md),
  [`plot_dw_partial_1d()`](https://openair-project.github.io/deweather/reference/plot_dw_partial_1d.md)
  and
  [`plot_dw_partial_2d()`](https://openair-project.github.io/deweather/reference/plot_dw_partial_2d.md).

- **Apply meteorological averaging** using
  [`simulate_dw_met()`](https://openair-project.github.io/deweather/reference/simulate_dw_met.md)
  to obtain a meteorologically normalised air quality timeseries.

Modelling can be computationally intensive and therefore **deweather**
makes use of the parallel processing, which should work on Windows,
Linux and Mac OSX.

![](reference/figures/feature-banner.png)

------------------------------------------------------------------------

## ⌛ Pre-1.0.0 deweather

**deweather** was overhauled in its 1.0.0 update. We believe this update
makes `deweather` more modern and flexible, but we appreciate users may
require access to or prefer the older version.

For this reason, the older, `gbm`-powered version of `deweather` can be
accessed at <https://github.com/openair-project/deweather-archive>.

Note that the above repository is provided for archival purposes only,
and is unlikely to recieve any future feature updates.

------------------------------------------------------------------------

## 📖 Documentation

All **deweather** functions are fully documented; access documentation
using R in your IDE of choice.

``` r
?deweather::build_dw_model
```

Documentation is also hosted online on the **package website**.

[![website](https://img.shields.io/badge/website-documentation-blue)](https://openair-project.github.io/deweather/)

A guide to the openair toolkit can be found in the **online book**,
which contains lots of code snippets, demonstrations of functionality,
and ideas for the application of **openair**’s various functions.

[![book](https://img.shields.io/badge/book-code_demos_and_ideas-blue)](https://openair-project.github.io/book/)

------------------------------------------------------------------------

## 🗃️ Installation

**deweather** is not yet on **CRAN**.

The development version of **deweather** can be installed from GitHub
using [pak](https://pak.r-lib.org/):

``` r
# install.packages("pak")
pak::pak("openair-project/deweather")
```

------------------------------------------------------------------------

🏛️ **deweather** is primarily maintained by [David
Carslaw](https://github.com/davidcarslaw).

📃 **deweather** is licensed under the [MIT
License](https://openair-project.github.io/deweather/LICENSE.html).

🧑‍💻 Contributions are welcome from the wider community. See the
[contributing
guide](https://openair-project.github.io/deweather/CONTRIBUTING.html)
and [code of
conduct](https://openair-project.github.io/deweather/CODE_OF_CONDUCT.html)
for more information.

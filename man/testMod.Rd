% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/testMod.R
\name{testMod}
\alias{testMod}
\title{Function to test different meteorological normalisation models.}
\usage{
testMod(
  input_data,
  vars = c("trend", "ws", "wd", "hour", "weekday", "air_temp"),
  pollutant = "nox",
  train.frac = 0.8,
  n.trees = NA,
  shrinkage = 0.1,
  interaction.depth = 5,
  bag.fraction = 0.5,
  n.minobsinnode = 10,
  cv.folds = 5,
  seed = 123,
  n.core = 4,
  plot = TRUE
)
}
\arguments{
\item{input_data}{Data frame to analyse. Must contain a POSIXct field called
\code{date}.}

\item{vars}{Explanatory variables to use. These variables will be used to
build the \code{\link[gbm:gbm]{gbm::gbm()}} model. Note that the model must include a trend
component. Several variables can be automatically calculated (see
\code{\link[=prepData]{prepData()}} for details).}

\item{pollutant}{The name of the variable to apply meteorological
normalisation to.}

\item{train.frac}{Fraction of data to train a model on. The model is tested
against the withheld 0.2 proportion.}

\item{n.trees}{Number of trees to use. If \code{n.trees = NA} then the
function will conduct cross-validation to calculate the optimum number.}

\item{shrinkage}{A shrinkage parameter applied to each tree in the expansion.
Also known as the learning rate or step-size reduction; \code{0.001} to \code{0.1}
usually work, but a smaller learning rate typically requires more trees.
Default is \code{0.1}.}

\item{interaction.depth}{Integer specifying the maximum depth of each tree
(i.e., the highest level of variable interactions allowed). A value of \code{1}
implies an additive model, a value of \code{2} implies a model with up to 2-way
interactions, etc. Default is \code{5}.}

\item{bag.fraction}{The fraction of the training set observations randomly
selected to propose the next tree in the expansion. This introduces
randomness into the model fit. If \code{bag.fraction < 1} then running the same
model twice will result in similar but different.}

\item{n.minobsinnode}{Integer specifying the minimum number of observations
in the terminal nodes of the trees. Note that this is the actual number of
observations, not the total weight.}

\item{cv.folds}{Number of cross-validation folds to perform. If \code{cv.folds > 1} then \code{\link[gbm:gbm]{gbm::gbm()}}, in addition to the usual fit, will perform a
cross-validation, calculate an estimate of generalization error returned in
\code{cv.error}.}

\item{seed}{Random number seed for reproducibility in returned model.}

\item{n.core}{Number of cores to use for parallel processing.}

\item{plot}{The default, \code{TRUE}, automatically prints a plot and two tables
of statistics to review the model output. \code{FALSE} disables this behaviour.}
}
\value{
Returns to be added.
}
\description{
Function to test different meteorological normalisation models.
}
\seealso{
\code{\link[=buildMod]{buildMod()}} for fitting a final model
}
\author{
David Carslaw
}

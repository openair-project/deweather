# Hyperparameter Cheat Sheet

Under the hood, `deweather` uses the `parsnip` package. This package
harmonises many different modelling engines, meaning `deweather` can
make it very easy to switch between engines with a consistent API.

However, for users familiar with the engine packages themselves (i.e.,
`xgboost`, `ligthgbm`, and `ranger`), it can make it challenging to
understand which hyperparameter you’re actually tweaking when setting
`trees` or `mtry` or any of the other arguments in
[`build_dw_model()`](https://openair-project.github.io/deweather/reference/build_dw_model.md).

The table in this article can be considered a ‘cheat sheet’ so you can
understand how different `deweather` arguments map onto their engine
equivalents.

| deweather/parsnip | xgboost          | lightgbm                | ranger        |
|:------------------|:-----------------|:------------------------|:--------------|
| tree_depth        | max_depth        | max_depth               | \-            |
| trees             | nrounds          | num_iterations          | num.trees     |
| learn_rate        | eta              | learning_rate           | \-            |
| mtry              | colsample_bynode | feature_fraction_bynode | mtry          |
| min_n             | min_child_weight | min_data_in_leaf        | min.node.size |
| loss_reduction    | gamma            | min_gain_to_split       | \-            |
| sample_size       | subsample        | \-                      | \-            |
| stop_iter         | early_stop       | \-                      | \-            |

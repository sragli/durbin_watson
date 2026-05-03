# Changelog

## [0.1.0] - 2026-05-03

### Added

- `DurbinWatson.compute/1` — computes the Durbin-Watson statistic from a list
  of residuals, returning `{:ok, d}` or `{:error, reason}`.
- `DurbinWatson.compute!/1` — bang variant that returns the statistic directly
  or raises `ArgumentError`.
- `DurbinWatson.interpret/2` — classifies the statistic as
  `:positive_autocorrelation`, `:no_autocorrelation`, or
  `:negative_autocorrelation` using configurable thresholds (default 1.5 / 2.5).
- `DurbinWatson.residuals_from_series/1` — fits $x_t = \beta_0 + \beta_1 t + \epsilon_t$
  using closed-form OLS estimators ($\hat{\beta}_1 = (\Sigma t x_t - n\bar{t}\bar{x}) / (n(n^2-1)/12)$),
  returning residuals and enabling a fully integrated pipeline from raw data to
  the autocorrelation test.
- `DurbinWatson.residuals_from_series_general_ols/1` — equivalent implementation
  using the general two-pass OLS formula (explicit $\Sigma(t-\bar{t})^2$ accumulation);
  kept as a reference and for adaptation to non-unit time steps.

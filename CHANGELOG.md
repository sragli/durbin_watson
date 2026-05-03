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

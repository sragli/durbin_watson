# DurbinWatson

An Elixir library for computing the **Durbin-Watson statistic** — a test used to detect autocorrelation in the residuals from a regression analysis.

## Background

### What is autocorrelation?

Autocorrelation (serial correlation) means that successive values in a sequence are correlated with each other. In the context of regression, the OLS (ordinary least squares) method assumes that the residuals are independent. If they are not — if a positive residual tends to be followed by another positive residual, for example — then:

- Standard errors of the regression coefficients are underestimated.
- Hypothesis tests (t-tests, F-tests) become unreliable.
- Confidence intervals are too narrow.

### The Durbin-Watson statistic

The statistic $d$ measures first-order autocorrelation in residuals. It is defined as:

$$d = \frac{\sum_{t=2}^{T}(e_t - e_{t-1})^2}{\sum_{t=1}^{T}e_t^2}$$

where $e_t$ is the residual at time $t$.

The value always falls in $[0, 4]$:

| $d$ value | Meaning |
|-----------|---------|
| $d = 0$ | Perfect positive autocorrelation |
| $0 < d < 1.5$ | Evidence of positive autocorrelation |
| $1.5 \leq d \leq 2.5$ | No significant autocorrelation (rule of thumb) |
| $2.5 < d < 4$ | Evidence of negative autocorrelation |
| $d = 4$ | Perfect negative autocorrelation |

When there is **no autocorrelation**, consecutive residuals are unrelated and $d \approx 2$.

When autocorrelation is **positive** (residuals trend together), the squared differences $(e_t - e_{t-1})^2$ are small, so $d$ is close to 0.

When autocorrelation is **negative** (residuals alternate in sign), the squared differences are large, so $d$ is close to 4.

### Limitations

- The Durbin-Watson test only detects **first-order** autocorrelation. It will not catch autocorrelation at longer lags.
- It requires residuals from a **linear regression** that includes an intercept.
- It is not reliable for autoregressive models that include a lagged dependent variable as a predictor (use the Durbin h-test instead).
- The critical values depend on the number of observations $n$ and the number of predictors $k$. The rule-of-thumb boundaries (1.5 / 2.5) are a practical approximation; for precise inference consult Durbin-Watson tables.

## Installation

Add `durbin_watson` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:durbin_watson, "~> 0.1.0"}
  ]
end
```

Then fetch dependencies:

```sh
mix deps.get
```

## Usage

### `DurbinWatson.residuals_from_series/1`

Fits the model $x_t = \beta_0 + \beta_1 t + \epsilon_t$ ($t = 1, 2, \ldots, n$) using
closed-form OLS estimators and returns the residuals $\hat{\epsilon}_t = x_t - (\hat{\beta}_0 + \hat{\beta}_1 t)$.

$$\hat{\beta}_1 = \frac{\sum t \cdot x_t - n\bar{t}\bar{x}}{n(n^2-1)/12}, \qquad \hat{\beta}_0 = \bar{x} - \hat{\beta}_1 \bar{t}$$

The denominator $\frac{n(n^2-1)}{12}$ is the closed-form value of $\sum(t-\bar{t})^2$ for the integer sequence $1 \ldots n$.

```elixir
series = [2.1, 4.3, 5.9, 8.2, 10.1]
{:ok, residuals} = DurbinWatson.residuals_from_series(series)
# residuals ≈ [-0.12, 0.26, -0.16, 0.22, -0.20]
```

Use this as the first step when you want to test a raw series for autocorrelation and do not have a separate regression model.

### `DurbinWatson.residuals_from_series_general_ols/1`

Mathematically equivalent to `residuals_from_series/1`, but uses the general two-pass OLS formula — explicitly accumulating $\sum(t-\bar{t})^2$ and
$\sum(t-\bar{t})(x_t-\bar{x})$ rather than the closed-form denominator.

```elixir
{:ok, residuals} = DurbinWatson.residuals_from_series_general_ols(series)
```

Prefer `residuals_from_series/1` for normal use. This variant is useful as a reference implementation or a starting point when adapting the code to
non-unit or irregular time steps.

### `DurbinWatson.compute/1`

Computes the statistic from a list of residuals. Returns `{:ok, d}` or `{:error, reason}`.

```elixir
residuals = [0.3, -0.1, 0.5, -0.2, 0.4]

{:ok, d} = DurbinWatson.compute(residuals)
# d is a float in [0, 4]
```

Pass residuals from any source — a statsmodels fit, a custom regression, or `residuals_from_series/1`.

### `DurbinWatson.compute!/1`

Bang variant — returns the statistic directly or raises `ArgumentError`.
Convenient when composing pipelines where you are certain the input is valid.

```elixir
d = DurbinWatson.compute!([0.3, -0.1, 0.5, -0.2, 0.4])
```

### `DurbinWatson.interpret/2`

Classifies the statistic into one of three atoms. Uses rule-of-thumb thresholds by default (lower: 1.5, upper: 2.5). Custom thresholds can be supplied.

```elixir
DurbinWatson.interpret(d)
# => :positive_autocorrelation | :no_autocorrelation | :negative_autocorrelation

# Stricter thresholds — flag anything outside 1.8–2.2
DurbinWatson.interpret(d, lower: 1.8, upper: 2.2)
```

#### Interpreting the result

| Result | What it means | Typical action |
|--------|---------------|----------------|
| `:no_autocorrelation` | Residuals appear independent | OLS assumptions satisfied; proceed normally |
| `:positive_autocorrelation` | Residuals drift in the same direction | Consider GLS, ARIMA, or adding a lagged term |
| `:negative_autocorrelation` | Residuals alternate sign | Check for over-differencing or model mis-specification |

### End-to-end example

Starting from a raw time series:

```elixir
series = [1.1, 2.3, 2.9, 4.2, 5.0]

series
|> DurbinWatson.residuals_from_series()
|> then(fn {:ok, res} -> DurbinWatson.compute!(res) end)
|> DurbinWatson.interpret()
# => :no_autocorrelation
```

Or from residuals you already have (e.g. from a regression library):

```elixir
residuals = [1, 2, 3, 4, 5]

residuals
|> DurbinWatson.compute!()
|> DurbinWatson.interpret()
# => :positive_autocorrelation  (d ≈ 0.073)
```

## Error cases

| Reason | Cause |
|--------|-------|
| `:insufficient_data` | List has fewer than 2 elements |
| `:zero_denominator` | All residuals are zero (only from `compute/1`) |

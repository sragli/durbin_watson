# DurbinWatson

An Elixir library for computing the **Durbin-Watson statistic** — a test used to detect autocorrelation in the residuals from a regression analysis.

The statistic $d$ is defined as:

$$d = \frac{\sum_{t=2}^{T}(e_t - e_{t-1})^2}{\sum_{t=1}^{T}e_t^2}$$

| Range | Interpretation |
|-------|---------------|
| $d \approx 0$ | Strong positive autocorrelation |
| $d \approx 2$ | No autocorrelation |
| $d \approx 4$ | Strong negative autocorrelation |

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

### `DurbinWatson.compute/1`

Computes the statistic from a list of residuals. Returns `{:ok, d}` or
`{:error, reason}`.

```elixir
residuals = [0.3, -0.1, 0.5, -0.2, 0.4]

{:ok, d} = DurbinWatson.compute(residuals)
# => {:ok, 3.56...}
```

### `DurbinWatson.compute!/1`

Bang variant — returns the statistic directly or raises `ArgumentError`.

```elixir
d = DurbinWatson.compute!([0.3, -0.1, 0.5, -0.2, 0.4])
```

### `DurbinWatson.interpret/2`

Classifies the statistic using rule-of-thumb thresholds (default lower: 1.5,
upper: 2.5). Custom thresholds can be supplied via options.

```elixir
DurbinWatson.interpret(d)
# => :positive_autocorrelation | :no_autocorrelation | :negative_autocorrelation

DurbinWatson.interpret(d, lower: 1.8, upper: 2.2)
```

### End-to-end example

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
| `:zero_denominator` | All residuals are zero |

defmodule DurbinWatson do
  @moduledoc """
  Computes the Durbin-Watson statistic for detecting autocorrelation in
  regression residuals.

  The statistic is defined as:

      d = Σ(eₜ - eₜ₋₁)² / Σeₜ²

  where eₜ are the residuals. The value ranges from 0 to 4:

  - ~2 → no autocorrelation
  - ~0 → positive autocorrelation
  - ~4 → negative autocorrelation
  """

  @doc """
  Computes the Durbin-Watson statistic from a list of residuals.

  Returns `{:ok, d}` where `d` is a float in [0, 4], or `{:error, reason}`
  if the input is invalid.

  ## Examples

      iex> DurbinWatson.compute([1, 2, 3, 4, 5])
      {:ok, 0.07272727272727272}

      iex> DurbinWatson.compute([])
      {:error, :insufficient_data}

      iex> DurbinWatson.compute([1])
      {:error, :insufficient_data}

  """
  @spec compute([number()]) :: {:ok, float()} | {:error, atom()}
  def compute(residuals) when is_list(residuals) and length(residuals) >= 2 do
    numerator =
      residuals
      |> Enum.zip(tl(residuals))
      |> Enum.reduce(0.0, fn {prev, curr}, acc -> acc + (curr - prev) * (curr - prev) end)

    denominator =
      Enum.reduce(residuals, 0.0, fn e, acc -> acc + e * e end)

    if denominator == 0.0 do
      {:error, :zero_denominator}
    else
      {:ok, numerator / denominator}
    end
  end

  def compute(_residuals), do: {:error, :insufficient_data}

  @doc """
  Same as `compute/1` but raises `ArgumentError` on invalid input.

  ## Examples

      iex> DurbinWatson.compute!([1, 2, 3, 4, 5])
      0.07272727272727272

  """
  @spec compute!([number()]) :: float()
  def compute!(residuals) do
    case compute(residuals) do
      {:ok, d} -> d
      {:error, reason} -> raise ArgumentError, "DurbinWatson.compute!/1 failed: #{reason}"
    end
  end

  @doc """
  Interprets a Durbin-Watson statistic value.

  Returns one of `:positive_autocorrelation`, `:no_autocorrelation`, or
  `:negative_autocorrelation` based on common rule-of-thumb thresholds
  (lower = 1.5, upper = 2.5).

  ## Examples

      iex> DurbinWatson.interpret(0.8)
      :positive_autocorrelation

      iex> DurbinWatson.interpret(2.0)
      :no_autocorrelation

      iex> DurbinWatson.interpret(3.2)
      :negative_autocorrelation

  """
  @spec interpret(float(), keyword()) :: atom()
  def interpret(d, opts \\ []) when is_number(d) do
    lower = Keyword.get(opts, :lower, 1.5)
    upper = Keyword.get(opts, :upper, 2.5)

    cond do
      d < lower -> :positive_autocorrelation
      d > upper -> :negative_autocorrelation
      true -> :no_autocorrelation
    end
  end

  @doc """
  Computes OLS residuals from a time series by fitting the linear model

      xₜ = β₀ + β₁·t + ϵₜ,  t = 1, 2, …, n

  and returning `ϵₜ = xₜ - (β₀ + β₁·t)` for each observation.

  The OLS estimators are:

      β₁ = (Σ t·xₜ  -  n·t̄·x̄) / (n(n²-1)/12)
      β₀ = x̄ - β₁·t̄

  where `t̄ = (n+1)/2` and the denominator uses the closed-form value of
  `Σ(t - t̄)²` for the integer sequence `1..n`.

  Returns `{:ok, residuals}` or `{:error, :insufficient_data}` when the series
  has fewer than 2 points.

  ## Examples

      iex> {:ok, res} = DurbinWatson.residuals_from_series([2.0, 4.0, 6.0, 8.0])
      iex> Enum.all?(res, fn r -> abs(r) < 1.0e-10 end)
      true

      iex> DurbinWatson.residuals_from_series([1])
      {:error, :insufficient_data}

  """
  @spec residuals_from_series([number()]) :: {:ok, [float()]} | {:error, atom()}
  def residuals_from_series(series) when is_list(series) and length(series) >= 2 do
    n = length(series)

    # t̄ = (n+1)/2 for t = 1..n
    mean_t = (n + 1) / 2.0
    mean_x = Enum.sum(series) / n

    # Σ t·xₜ in a single pass using 1-based index
    sum_tx =
      series
      |> Enum.with_index(1)
      |> Enum.reduce(0.0, fn {x, t}, acc -> acc + t * x end)

    # Closed-form Σ(t - t̄)² = n(n²-1)/12 for t = 1..n
    ss_tt = n * (n * n - 1) / 12.0

    beta1 = (sum_tx - n * mean_t * mean_x) / ss_tt
    beta0 = mean_x - beta1 * mean_t

    residuals =
      series
      |> Enum.with_index(1)
      |> Enum.map(fn {x, t} -> x - (beta0 + beta1 * t) end)

    {:ok, residuals}
  end

  def residuals_from_series(_), do: {:error, :insufficient_data}

  @doc """
  Computes OLS residuals by fitting `xₜ = β₀ + β₁·t + ϵₜ` using the general
  two-pass OLS formula — explicitly accumulating `Σ(t - t̄)²` and `Σ(t - t̄)(xₜ - x̄)`
  rather than relying on the closed-form denominator `n(n²-1)/12`.

  Mathematically equivalent to `residuals_from_series/1` for integer time steps
  `t = 1..n`. Prefer `residuals_from_series/1` for normal use; this variant is
  useful as a reference or when adapting the code to non-unit time steps.

  Returns `{:ok, residuals}` or `{:error, :insufficient_data}` when the series
  has fewer than 2 points.

  ## Examples

      iex> {:ok, res} = DurbinWatson.residuals_from_series_general_ols([2.0, 4.0, 6.0, 8.0])
      iex> Enum.all?(res, fn r -> abs(r) < 1.0e-10 end)
      true

      iex> DurbinWatson.residuals_from_series_general_ols([1])
      {:error, :insufficient_data}

  """
  @spec residuals_from_series_general_ols([number()]) :: {:ok, [float()]} | {:error, atom()}
  def residuals_from_series_general_ols(series) when is_list(series) and length(series) >= 2 do
    n = length(series)
    ts = Enum.map(1..n, & &1)

    mean_t = Enum.sum(ts) / n
    mean_x = Enum.sum(series) / n

    {ss_tt, ss_tx} =
      Enum.zip(ts, series)
      |> Enum.reduce({0.0, 0.0}, fn {t, x}, {stt, stx} ->
        dt = t - mean_t
        {stt + dt * dt, stx + dt * (x - mean_x)}
      end)

    beta1 = ss_tx / ss_tt
    beta0 = mean_x - beta1 * mean_t

    residuals =
      Enum.zip(ts, series)
      |> Enum.map(fn {t, x} -> x - (beta0 + beta1 * t) end)

    {:ok, residuals}
  end

  def residuals_from_series_general_ols(_), do: {:error, :insufficient_data}
end

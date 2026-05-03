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
end

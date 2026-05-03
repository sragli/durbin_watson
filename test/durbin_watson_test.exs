defmodule DurbinWatsonTest do
  use ExUnit.Case
  doctest DurbinWatson

  describe "compute/1" do
    test "returns correct statistic for simple increasing residuals" do
      # numerator: (2-1)²+(3-2)²+(4-3)²+(5-4)² = 4
      # denominator: 1+4+9+16+25 = 55
      assert {:ok, d} = DurbinWatson.compute([1, 2, 3, 4, 5])
      assert_in_delta d, 4 / 55, 1.0e-10
    end

    test "returns correct statistic for alternating residuals (high d)" do
      # alternating sign → high numerator → d approaches 4
      residuals = [1, -1, 1, -1, 1]
      assert {:ok, d} = DurbinWatson.compute(residuals)
      assert d > 3.0
    end

    test "returns correct statistic for constant residuals (d = 0)" do
      assert {:ok, d} = DurbinWatson.compute([3, 3, 3, 3])
      assert_in_delta d, 0.0, 1.0e-10
    end

    test "works with two elements (minimum valid input)" do
      assert {:ok, d} = DurbinWatson.compute([2, 4])
      # numerator: (4-2)² = 4; denominator: 4+16 = 20
      assert_in_delta d, 4 / 20, 1.0e-10
    end

    test "works with floats" do
      assert {:ok, d} = DurbinWatson.compute([0.1, -0.2, 0.3])
      assert is_float(d)
    end

    test "returns :insufficient_data for empty list" do
      assert DurbinWatson.compute([]) == {:error, :insufficient_data}
    end

    test "returns :insufficient_data for single-element list" do
      assert DurbinWatson.compute([42]) == {:error, :insufficient_data}
    end

    test "returns :insufficient_data for non-list input" do
      assert DurbinWatson.compute(nil) == {:error, :insufficient_data}
      assert DurbinWatson.compute(1.0) == {:error, :insufficient_data}
    end

    test "returns :zero_denominator when all residuals are zero" do
      assert DurbinWatson.compute([0, 0, 0]) == {:error, :zero_denominator}
    end
  end

  describe "compute!/1" do
    test "returns the statistic directly on success" do
      assert is_float(DurbinWatson.compute!([1, -1, 1]))
    end

    test "raises ArgumentError on insufficient data" do
      assert_raise ArgumentError, ~r/insufficient_data/, fn ->
        DurbinWatson.compute!([])
      end
    end

    test "raises ArgumentError on zero denominator" do
      assert_raise ArgumentError, ~r/zero_denominator/, fn ->
        DurbinWatson.compute!([0, 0, 0])
      end
    end
  end

  describe "interpret/2" do
    test "classifies low d as positive autocorrelation" do
      assert DurbinWatson.interpret(0.5) == :positive_autocorrelation
      assert DurbinWatson.interpret(1.4) == :positive_autocorrelation
    end

    test "classifies d around 2 as no autocorrelation" do
      assert DurbinWatson.interpret(1.5) == :no_autocorrelation
      assert DurbinWatson.interpret(2.0) == :no_autocorrelation
      assert DurbinWatson.interpret(2.5) == :no_autocorrelation
    end

    test "classifies high d as negative autocorrelation" do
      assert DurbinWatson.interpret(2.6) == :negative_autocorrelation
      assert DurbinWatson.interpret(3.9) == :negative_autocorrelation
    end

    test "respects custom lower and upper thresholds" do
      assert DurbinWatson.interpret(1.6, lower: 1.8, upper: 2.2) == :positive_autocorrelation
      assert DurbinWatson.interpret(2.0, lower: 1.8, upper: 2.2) == :no_autocorrelation
      assert DurbinWatson.interpret(2.3, lower: 1.8, upper: 2.2) == :negative_autocorrelation
    end

    test "accepts integer values" do
      assert DurbinWatson.interpret(0) == :positive_autocorrelation
      assert DurbinWatson.interpret(4) == :negative_autocorrelation
    end
  end

  describe "compute/1 |> interpret/2 pipeline" do
    test "strongly autocorrelated residuals yield positive autocorrelation" do
      residuals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      {:ok, d} = DurbinWatson.compute(residuals)
      assert DurbinWatson.interpret(d) == :positive_autocorrelation
    end

    test "alternating residuals yield negative autocorrelation" do
      residuals = [1, -1, 1, -1, 1, -1, 1, -1]
      {:ok, d} = DurbinWatson.compute(residuals)
      assert DurbinWatson.interpret(d) == :negative_autocorrelation
    end
  end
end

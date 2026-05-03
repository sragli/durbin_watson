defmodule DurbinWatson.MixProject do
  use Mix.Project

  def project do
    [
      app: :durbin_watson,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "DurbinWatson",
        extras: ["README.md", "CHANGELOG.md", "LICENSE"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end

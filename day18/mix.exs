defmodule Day18.Mixfile do
  use Mix.Project

  def application do
    [applications: []]
  end

  def project do
    [app: :day18,
     version: "1.0.0",
     deps: deps()]
  end

  defp deps do
    [{:nimble_parsec, "~> 1.1"}]
  end
end

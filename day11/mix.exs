defmodule Day11.Mixfile do
  use Mix.Project

  def application do
    [applications: [:gen_state_machine]]
  end

  def project do
    [app: :day11,
     version: "1.0.0",
     deps: deps()]
  end

  defp deps do
    [{:gen_state_machine, "~> 3.0"}]
  end
end

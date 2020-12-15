defmodule Navigation do
  def parse(line) do
    [command, amount] = Regex.run(~r/([NSEWLRF])(\d+)/, line, capture: :all_but_first)
    {String.to_atom(command), String.to_integer(amount)}
  end

  def start_point() do
    {{1, 10}, {0, 0}}
  end

  def move({dir, pos}, {cmd, amount}) when cmd in [:N, :S, :E, :W] do
    {offset(dir, cmd, amount), pos}
  end

  def move({dir, pos}, {cmd, amount}) when cmd in [:L, :R] do
    {turn(dir, {cmd, amount}), pos}
  end

  def move({dir, pos}, {:F, amount}) do
    {dir, offset(pos, dir, amount)}
  end

  defp offset({n, e}, {n_inc, e_inc}, amount) do
    {n + amount*n_inc, e + amount*e_inc}
  end
  defp offset({n, e}, dir, amount) do
    case dir do
      :N -> {n+amount, e}
      :E -> {n, e+amount}
      :S -> {n-amount, e}
      :W -> {n, e-amount}
    end
  end

  defp turn(dir, {_, 0}), do: dir
  defp turn({n, e}, {:L, 90}) do
    {e, -n}
  end
  defp turn({n, e}, {:R, 90}) do
    {-e, n}
  end
  defp turn(dir, {cmd, amount}) do
    turn(dir, {cmd, 90}) |> turn({cmd, amount-90})
  end
end

System.argv()
|> hd()
|> File.stream!()
|> Stream.map(&Navigation.parse/1)
|> Stream.scan(Navigation.start_point(), &Navigation.move(&2, &1))
|> Stream.take(-1)
|> Enum.to_list()
|> IO.inspect()

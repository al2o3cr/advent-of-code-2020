defmodule Navigation do
  def parse(line) do
    [command, amount] = Regex.run(~r/([NSEWLRF])(\d+)/, line, capture: :all_but_first)
    {String.to_atom(command), String.to_integer(amount)}
  end

  def start_point() do
    {:E, {0,0}}
  end

  def move({dir, pos}, {cmd, amount}) when cmd in [:N, :S, :E, :W] do
    {dir, offset(pos, cmd, amount)}
  end

  def move({dir, pos}, {cmd, amount}) when cmd in [:L, :R] do
    {turn(dir, {cmd, amount}), pos}
  end

  def move({dir, pos}, {:F, amount}) do
    {dir, offset(pos, dir, amount)}
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
  defp turn(dir, {:L, 90}) do
    case dir do
      :N -> :W
      :E -> :N
      :S -> :E
      :W -> :S
    end
  end
  defp turn(dir, {:R, 90}) do
    case dir do
      :N -> :E
      :E -> :S
      :S -> :W
      :W -> :N
    end
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

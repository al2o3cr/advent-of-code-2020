defmodule Adapters do
  def count(adapters, jolts) do
    {result, _acc} = count(adapters, jolts, %{})

    result
  end

  def count([0], 0, acc), do: {1, acc}
  def count([], _, acc), do: {0, acc}
  def count([a | _], jolts, acc) when a < jolts, do: {0, acc}
  def count([a | rest], jolts, acc) when a > jolts, do: count(rest, jolts, acc)
  def count([a | rest], jolts, acc) when a == jolts do
    case Map.get(acc, jolts) do
      nil ->
        {one_down, acc} = count(rest, jolts-1, acc)
        {two_down, acc} = count(rest, jolts-2, acc)
        {three_down, acc} = count(rest, jolts-3, acc)
        result = one_down + two_down + three_down
        {result, Map.put(acc, jolts, result)}

      cached_count ->
        {cached_count, acc}
    end
  end
end

adapters =
  System.argv()
  |> hd()
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.to_integer/1)
  |> Stream.concat([0])
  |> Enum.sort(:desc)

max = hd(adapters)

adapters
|> Adapters.count(max)
|> IO.inspect()

defmodule TreeMap do
  def walk(stream, step) do
    Stream.transform(stream, {0, 0}, &do_walk(&1, step, &2))
  end

  defp do_walk(trees, step, {row, col}) do
    {
      [{trees, row, col}],
      {row + 1, Integer.mod(col + step, String.length(trees))}
    }
  end

  def has_tree?({trees, _row, col}) do
    String.at(trees, col) == "#"
  end
end

System.argv()
|> hd()
|> File.stream!()
|> Stream.map(&String.trim/1)
|> TreeMap.walk(3)
|> Stream.filter(&TreeMap.has_tree?/1)
|> Enum.count()
|> IO.inspect()

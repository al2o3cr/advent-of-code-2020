defmodule TreeMap do
  def walk(stream, col_step, row_step) do
    Stream.transform(stream, {0, 0}, &do_walk(&1, col_step, row_step, &2))
  end

  defp do_walk(trees, col_step, row_step, {row, col}) do
    if Integer.mod(row, row_step) == 0 do
      {
        [{trees, row, col}],
        {row + 1, Integer.mod(col + col_step, String.length(trees))}
      }
    else
      {
        [],
        {row + 1, col}
      }
    end
  end

  def has_tree?({trees, _row, col}) do
    String.at(trees, col) == "#"
  end
end

count_trees = fn (col_step, row_step) ->
  System.argv()
  |> hd()
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> TreeMap.walk(col_step, row_step)
  |> Stream.filter(&TreeMap.has_tree?/1)
  |> Enum.count()
end

[
  count_trees.(1,1),
  count_trees.(3,1),
  count_trees.(5,1),
  count_trees.(7,1),
  count_trees.(1,2)
]
|> Enum.reduce(1, &Kernel.*/2)
|> IO.inspect()

defmodule Bitmasks do
  use Bitwise

  def parse("mask = " <> mask) do
    {:mask, String.trim(mask) |> decode_mask()}
  end

  def parse("mem" <> line) do
    [addr_s, value_s] = Regex.run(~r/\[(\d+)\] = (\d+)/, line, capture: :all_but_first)
    {:set, String.to_integer(addr_s), String.to_integer(value_s)}
  end

  defp decode_mask(s) do
    String.split(s, "", trim: true)
    |> Enum.with_index()
    |> Enum.reduce({0, []}, &mask_step/2)
  end

  defp mask_step({el, idx}, {ones, floating}) do
    case el do
      "X" -> {ones <<< 1, [35-idx | floating]}
      "0" -> {ones <<< 1, floating}
      "1" -> {(ones <<< 1) ||| 1, floating}
    end
  end

  def run(stream) do
    Stream.transform(stream, {{0, 0}, %{}}, &run_step/2)
  end

  defp run_step({:mask, mask}, {_old_mask, mem}) do
    {[], {mask, mem}}
  end

  defp run_step({:set, addr, value}, {mask, mem}) do
    to_write = apply_mask_and_floating(addr, mask)
    new_mem = Enum.reduce(to_write, mem, &Map.put(&2, &1, value))
    {[new_mem], {mask, new_mem}}
  end

  defp apply_mask(value, {zeros, ones}) do
    (value &&& ~~~zeros) ||| ones
  end
  
  defp apply_mask_and_floating(value, {ones, floating}) do
    base_value = apply_mask(value, {0, ones})

    options(floating)
    |> IO.inspect()
    |> Enum.map(&apply_mask(base_value, &1))
  end

  defp options([]), do: [{0,0}]
  defp options([f1 | rest]) do
    options(rest)
    |> Enum.flat_map(fn {zeros, ones} -> [{zeros ||| (1 <<< f1), ones}, {zeros, ones ||| (1 <<< f1)}] end)
  end
end

System.argv()
|> hd()
|> File.stream!()
|> Stream.map(&Bitmasks.parse/1)
|> Bitmasks.run()
|> Stream.take(-1)
|> Enum.to_list()
|> hd()
|> Map.values()
|> Enum.sum()
|> IO.inspect()

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
    |> Enum.reduce({0, 0}, &mask_step/2)
  end

  defp mask_step(el, {zeros, ones}) do
    case el do
      "X" -> {zeros <<< 1, ones <<< 1}
      "0" -> {(zeros <<< 1) ||| 1, ones <<< 1}
      "1" -> {zeros <<< 1, (ones <<< 1) ||| 1}
    end
  end

  def run(stream) do
    Stream.transform(stream, {{0, 0}, %{}}, &run_step/2)
  end

  defp run_step({:mask, mask}, {_old_mask, mem}) do
    {[], {mask, mem}}
  end

  defp run_step({:set, addr, value}, {mask, mem}) do
    written = apply_mask(value, mask)
    IO.inspect(written, label: "write to #{addr}")
    new_mem = Map.put(mem, addr, written)
    {[new_mem], {mask, new_mem}}
  end

  defp apply_mask(value, {zeros, ones}) do
    (value &&& ~~~zeros) ||| ones
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

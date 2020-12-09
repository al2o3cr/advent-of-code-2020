defmodule ComboCheck do
  def valid?([], _), do: false
  def valid?([el | rest], result) do
    Enum.any?(rest, & (&1 + el) == result) or valid?(rest, result)
  end
end

[input_file, preamble_s] = System.argv()

preamble = String.to_integer(preamble_s)

File.stream!(input_file)
|> Stream.map(&String.trim/1)
|> Stream.map(&String.to_integer/1)
|> Stream.chunk_every(preamble + 1, 1)
|> Stream.map(&Enum.reverse/1)
|> Stream.map(fn [el | rest] -> {el, ComboCheck.valid?(rest, el)} end)
|> Enum.find(& elem(&1, 1) == false)
|> IO.inspect()

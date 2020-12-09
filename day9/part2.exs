defmodule ComboCheck do
  def valid?([], _), do: false
  def valid?([el | rest], result) do
    Enum.any?(rest, & (&1 + el) == result) or valid?(rest, result)
  end
end

[input_file, preamble_s] = System.argv()

preamble = String.to_integer(preamble_s)

input_numbers = 
  File.stream!(input_file)
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.to_integer/1)
  |> Enum.to_list()

bad_number =
  input_numbers
  |> Stream.chunk_every(preamble + 1, 1)
  |> Stream.map(&Enum.reverse/1)
  |> Stream.map(fn [el | rest] -> {el, ComboCheck.valid?(rest, el)} end)
  |> Enum.find(& elem(&1, 1) == false)
  |> elem(0)

(2..length(input_numbers))
|> Stream.flat_map(&Stream.chunk_every(input_numbers, &1, 1))
|> Stream.map(&{&1, Enum.sum(&1)})
|> Enum.find(& elem(&1, 1) == bad_number)
|> elem(0)
|> Enum.min_max()
|> IO.inspect()

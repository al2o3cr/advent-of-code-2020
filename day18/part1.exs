defmodule HomeworkParser do
  import NimbleParsec

  number_string = ascii_string([?0..?9], min: 1) |> map({String, :to_integer, []})
  operator = ignore(string(" ")) |> concat(choice([string("+"), string("*")])) |> ignore(string(" ")) |> map({String, :to_existing_atom, []})
  lparen = ascii_char([?(])
  rparen = ascii_char([?)])

  number_or_group = choice([ignore(lparen) |> concat(parsec(:expression)) |> ignore(rparen) |> wrap(), number_string])
  defparsec :expression, number_or_group |> repeat(operator |> concat(number_or_group) |> wrap())

  def parse(line) do
    {:ok, result, "", _, _, _} = expression(line)

    result
  end

  def eval([:+, b], a) when is_integer(b), do: a + b
  def eval([:*, b], a) when is_integer(b), do: a * b
  def eval([op, b], a) when is_list(b), do: eval([op, eval(b)], a)

  def eval(a) when is_integer(a), do: a
  def eval([hd | rest]) do
    Enum.reduce(rest, eval(hd), &eval/2)
  end
end

# s = "1 + (2 * 3 + 4) + 5"
# s = "1 + 2 * 3 + 5"

System.argv()
|> hd()
|> File.stream!()
|> Stream.map(&String.trim/1)
|> Stream.map(&HomeworkParser.parse/1)
|> Stream.map(&HomeworkParser.eval/1)
|> Enum.to_list()
|> IO.inspect()
|> Enum.sum()
|> IO.inspect(label: "total")

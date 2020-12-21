defmodule HomeworkParser do
  import NimbleParsec

  number_string = ascii_string([?0..?9], min: 1) |> map({String, :to_integer, []})
  operator_plus = ignore(string(" ")) |> concat(string("+")) |> ignore(string(" ")) |> map({String, :to_existing_atom, []})
  operator_times = ignore(string(" ")) |> concat(string("*")) |> ignore(string(" ")) |> map({String, :to_existing_atom, []})
  lparen = ascii_char([?(])
  rparen = ascii_char([?)])

  number_or_group = choice([ignore(lparen) |> concat(parsec(:expression)) |> ignore(rparen), number_string])
  defparsec :term, number_or_group |> optional(operator_plus |> concat(parsec(:term)) |> wrap()) |> wrap() |> map({:swizzle, []})
  defparsec :expression, parsec(:term) |> optional(operator_times |> concat(parsec(:expression))) |> wrap() |> map({:swizzle, []})

  defp swizzle(a) when is_tuple(a), do: a
  defp swizzle([a]), do: a
  defp swizzle([a, b, c]), do: {b, a, c}
  defp swizzle([a, [b, c]]), do: {b, a, c}

  def parse(line) do
    {:ok, [result], "", _, _, _} = expression(line)

    result
  end

  def eval(a) when is_integer(a), do: a
  def eval({op, a, b}), do: Kernel.apply(Kernel, op, [eval(a), eval(b)])
end

System.argv()
|> hd()
|> File.stream!()
|> Stream.map(&String.trim/1)
|> Stream.map(&HomeworkParser.parse/1)
|> Stream.each(&IO.inspect/1)
|> Stream.map(&HomeworkParser.eval/1)
|> Enum.to_list()
|> IO.inspect()
|> Enum.sum()
|> IO.inspect(label: "total")

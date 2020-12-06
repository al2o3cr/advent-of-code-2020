defmodule InParagraphs do
  def chunk(stream) do
    Stream.chunk_while(stream, [], &do_chunk/2, &finish_chunk/1)
  end

  defp do_chunk("\n", []), do: {:cont, []}
  defp do_chunk("\n", acc), do: {:cont, Enum.reverse(acc), []}
  defp do_chunk(line, acc), do: {:cont, [line | acc]}

  defp finish_chunk([]), do: {:cont, []}
  defp finish_chunk(acc), do: {:cont, Enum.reverse(acc), []}
end

defmodule SurveyResults do
  def count_all_answered(list) do
    list
    |> Enum.map(&Regex.scan(~r/[a-z]/, &1))
    |> Enum.map(&MapSet.new/1)
    |> Enum.reduce(&MapSet.intersection/2)
    |> MapSet.size()
  end
end

System.argv()
|> hd()
|> File.stream!()
|> InParagraphs.chunk()
|> Stream.map(&SurveyResults.count_all_answered/1)
|> Enum.sum()
|> IO.inspect()

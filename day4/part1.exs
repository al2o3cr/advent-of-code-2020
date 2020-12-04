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

defmodule Passport do

  defstruct [:byr, :iyr, :eyr, :hgt, :hcl, :ecl, :pid, :cid]

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end

  def parse(line) do
    Regex.scan(~r/([^\s:]+):(\S+)/, line, capture: :all_but_first)
    |> Enum.map(fn [a,b] -> {String.to_existing_atom(a), b} end)
    |> new()
  end

  def valid?(passport) do
    !any_blank?(passport) or only_missing_cid?(passport)
  end

  defp any_blank?(p) do
    is_nil(p.byr) or
    is_nil(p.iyr) or
    is_nil(p.eyr) or
    is_nil(p.hgt) or
    is_nil(p.hcl) or
    is_nil(p.ecl) or
    is_nil(p.pid) or
    is_nil(p.cid)
  end

  defp only_missing_cid?(p) do
    !any_blank?(%{p | cid: "NOT BLANK"})
  end
end

System.argv()
|> hd()
|> File.stream!()
|> InParagraphs.chunk()
|> Stream.map(&Enum.join/1)
|> Stream.map(&Passport.parse/1)
|> Stream.filter(&Passport.valid?/1)
|> Enum.count()
|> IO.inspect()

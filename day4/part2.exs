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
  @fields [:byr, :iyr, :eyr, :hgt, :hcl, :ecl, :pid, :cid]
  defstruct @fields

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end

  def parse(line) do
    Regex.scan(~r/([^\s:]+):(\S+)/, line, capture: :all_but_first)
    |> Enum.map(&do_parse/1)
    |> new()
  end

  defp do_parse(["byr", s]), do: {:byr, extract_4_digits(s)}
  defp do_parse(["iyr", s]), do: {:iyr, extract_4_digits(s)}
  defp do_parse(["eyr", s]), do: {:eyr, extract_4_digits(s)}
  defp do_parse(["hgt", s]), do: {:hgt, extract_with_unit(s)}
  defp do_parse(["hcl", s]), do: {:hcl, extract_color(s)}
  defp do_parse(["ecl", s]), do: {:ecl, extract_hair_color(s)}
  defp do_parse(["pid", s]), do: {:pid, extract_passport_number(s)}
  defp do_parse(["cid", s]), do: {:cid, s}

  def valid?(passport) do
    Enum.all?(@fields, &do_valid?(passport, &1))
  end

  defp do_valid?(p, :byr), do: p.byr in 1920..2002
  defp do_valid?(p, :iyr), do: p.iyr in 2010..2020
  defp do_valid?(p, :eyr), do: p.eyr in 2020..2030
  defp do_valid?(p, :hgt) do
    case p.hgt do
      {:cm, n} -> n in 150..193
      {:in, n} -> n in 59..76
      nil -> false
    end
  end
  defp do_valid?(p, :hcl), do: !is_nil(p.hcl)
  defp do_valid?(p, :ecl), do: !is_nil(p.ecl)
  defp do_valid?(p, :pid), do: !is_nil(p.pid)
  defp do_valid?(_, :cid), do: true

  defp extract_4_digits(s) do
    Regex.run(~r/^\d{4}$/, s, capture: :first)
    |> hd()
    |> Integer.parse()
    |> case do
      {n, ""} -> n
      {_, _} -> nil
      :error -> nil
    end
  end

  defp extract_with_unit(s) do
    case Integer.parse(s) do
      {n, "cm"} -> {:cm, n}
      {n, "in"} -> {:in, n}
      {_, _} -> nil
      :error -> nil
    end
  end

  defp extract_color(s) do
    case Regex.run(~r/^#[0-9a-f]{6}$/, s, capture: :first) do
      [c] -> c
      nil -> nil
    end
  end

  defp extract_hair_color(s) do
    case Regex.run(~r/^amb|blu|brn|gry|grn|hzl|oth$/, s, capture: :first) do
      [c] -> c
      nil -> nil
    end
  end

  defp extract_passport_number(s) do
    case Regex.run(~r/^[0-9]{9}$/, s, capture: :first) do
      [c] -> c
      nil -> nil
    end
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

defmodule PasswordChecker do
  def decode_line(line) do
    [_, start_s, end_s, key, password] = Regex.run(~r/(\d+)-(\d+) ([a-z]): ([a-z]+)/, line)

    {
      String.to_integer(start_s)..String.to_integer(end_s),
      key,
      password
    }
  end

  def count_letter(key, password) do
    do_count_letter(key, password, 0)
  end

  defp do_count_letter(_, "", count), do: count

  defp do_count_letter(<<k::utf8>> = key, <<k::utf8>> <> rest, count) do
    do_count_letter(key, rest, count + 1)
  end

  defp do_count_letter(key, <<_::utf8>> <> rest, count) do
    do_count_letter(key, rest, count)
  end

  def valid_entry?({valid_counts, key, password}) do
    Enum.member?(valid_counts, count_letter(key, password))
  end
end

File.stream!("input.txt")
|> Stream.map(&PasswordChecker.decode_line/1)
|> Stream.filter(&PasswordChecker.valid_entry?/1)
|> Enum.count()
|> IO.inspect()


defmodule PasswordChecker do
  def decode_line(line) do
    [_, pos1, pos2, key, password] = Regex.run(~r/(\d+)-(\d+) ([a-z]): ([a-z]+)/, line)

    {
      String.to_integer(pos1),
      String.to_integer(pos2),
      key,
      password
    }
  end

  def has_letter_at?(password, key, pos) do
    String.at(password, pos - 1) == key
  end

  def valid_entry?({pos1, pos2, key, password}) do
    has1 = has_letter_at?(password, key, pos1)
    has2 = has_letter_at?(password, key, pos2)
    # Y U NO XOR ELIXIR
    (has1 and !has2) or (!has1 and has2)
  end
end

File.stream!("input.txt")
|> Stream.map(&PasswordChecker.decode_line/1)
|> Stream.filter(&PasswordChecker.valid_entry?/1)
|> Enum.count()
|> IO.inspect()


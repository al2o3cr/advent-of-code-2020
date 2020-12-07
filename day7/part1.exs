defmodule RegexHelper do
  def scan_named(regex, input) do
    names = Regex.names(regex)

    Regex.scan(regex, input, capture: names)
    |> Enum.map(&format_result(&1, names))
  end

  defp format_result(matches, names) do
    names
    |> Enum.zip(matches)
    |> Enum.into(%{})
  end
end

defmodule Haversacks do
  @contains_regex ~r/(?<base_modifier>\w+) (?<base_color>\w+) bags contain (?<contents>[^.]+)\./
  @one_bag_count ~r/(?<count>\d+) (?<modifier>\w+) (?<color>\w+)/

  def parse(line) do
    Regex.named_captures(@contains_regex, line)
    |> Map.update("contents", [], &RegexHelper.scan_named(@one_bag_count, &1))
  end

  def format(%{"base_color" => color, "base_modifier" => modifier, "contents" => contents}) do
    {{color, modifier}, Enum.map(contents, &format_content/1)}
  end

  defp format_content(%{"color" => color, "modifier" => modifier, "count" => count}) do
    {{color, modifier}, String.to_integer(count)}
  end

  def count_containing(rules, needle) do
    rules
    |> Map.keys()
    |> Enum.count(&can_contain?(rules, needle, &1))
  end

  def can_contain?(rules, needle, key) do
    contents = Map.get(rules, key)

    contents_contain?(rules, contents, needle)
  end

  defp contents_contain?(rules, contents, needle) do
    List.keymember?(contents, needle, 0) or
    Enum.any?(contents, fn {k, _} -> can_contain?(rules, needle, k) end)
  end
end

System.argv()
|> hd()
|> File.stream!()
|> Stream.map(&Haversacks.parse/1)
|> Stream.map(&Haversacks.format/1)
|> Map.new()
|> Haversacks.count_containing({"gold", "shiny"})
|> IO.inspect()


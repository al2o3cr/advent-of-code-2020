defmodule InParagraphs do
  def chunk(stream) do
    Stream.chunk_while(stream, [], &do_chunk/2, &finish_chunk/1)
  end

  defp do_chunk("\n", []), do: {:cont, []}
  defp do_chunk("\n", acc), do: {:cont, Enum.reverse(acc), []}
  defp do_chunk(line, acc), do: {:cont, [String.trim(line) | acc]}

  defp finish_chunk([]), do: {:cont, []}
  defp finish_chunk(acc), do: {:cont, Enum.reverse(acc), []}
end

defmodule TicketRule do
  def parse(line) do
    [class, r1_l, r1_h, r2_l, r2_h] = Regex.run(~r/([a-z ]+): (\d+)-(\d+) or (\d+)-(\d+)/, line, capture: :all_but_first)

    {class, {to_range(r1_l, r1_h), to_range(r2_l, r2_h)}}
  end

  defp to_range(l, h) do
    String.to_integer(l)..String.to_integer(h)
  end

  def matches?(value, {_, {r1, r2}}) do
    (value in r1) or (value in r2)
  end
end

defmodule Ticket do
  def parse(line) do
    String.split(line, ",")
    |> Enum.map(&String.to_integer/1)
  end

  def valid?(ticket, rules) do
    Enum.all?(ticket, &any_match?(&1, rules))
  end

  def bad_value(ticket, rules) do
    Enum.find(ticket, &!any_match?(&1, rules))
  end

  defp any_match?(value, rules) do
    Enum.any?(rules, &TicketRule.matches?(value, &1))
  end

  def all_matching_rules(ticket, rules) do
    Enum.map(ticket, &matching_rules(&1, rules))
  end

  defp matching_rules(value, rules) do
    rules
    |> Enum.filter(&TicketRule.matches?(value, &1))
    |> Enum.map(&elem(&1, 0))
    |> MapSet.new()
  end

  def combine_rules(l1, l2) do
    Enum.zip(l1, l2)
    |> Enum.map(fn {e1, e2} -> MapSet.intersection(e1, e2) end)
  end
end

defmodule Solver do
  def solve(entries, acc \\ %{})
  def solve([], acc), do: acc
  def solve(entries, acc) do
    {found_set, idx} = found = Enum.find(entries, fn {s, _} -> MapSet.size(s) == 1 end)

    found_value = Enum.to_list(found_set) |> hd()

    remaining_entries =
      (entries -- [found])
      |> Enum.map(fn {s, l} -> {MapSet.delete(s, found_value), l} end)

    solve(remaining_entries, Map.put(acc, idx, found_value))
  end
end

[rule_lines, ["your ticket:", your_ticket_line], ["nearby tickets:" | other_ticket_lines]] =
  System.argv()
  |> hd()
  |> File.stream!()
  |> InParagraphs.chunk()
  |> Enum.to_list()

rules = Map.new(rule_lines, &TicketRule.parse/1)

your_ticket = Ticket.parse(your_ticket_line)

other_tickets = Enum.map(other_ticket_lines, &Ticket.parse/1)

other_tickets
|> Enum.filter(&Ticket.valid?(&1, rules))
|> Enum.map(&Ticket.all_matching_rules(&1, rules))
|> Enum.reduce(&Ticket.combine_rules/2)
|> Enum.with_index()
|> Solver.solve()
|> IO.inspect()
|> Enum.filter(fn {_, v} -> String.starts_with?(v, "departure") end)
|> Enum.map(fn {idx, _} -> Enum.at(your_ticket, idx) end)
|> Enum.reduce(&Kernel.*/2)
|> IO.inspect()

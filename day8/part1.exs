defmodule GameConsole do
  def read(stream) do
    stream
    |> Stream.map(&GameConsole.parse/1)
    |> Stream.with_index()
    |> Map.new(fn {v, k} -> {k, v} end)
  end

  def parse(line) do
    [instruction_s, offset_s] = Regex.run(~r/^(nop|jmp|acc) ([+-]\d+)/, line, capture: :all_but_first)

    case {instruction_s, String.to_integer(offset_s)} do
      {"nop", _} -> :nop
      {"jmp", offset} -> {:jmp, offset}
      {"acc", operand} -> {:acc, operand}
    end
  end

  def execute(program, {pc, acc}) do
    case program[pc] do
      :nop -> {pc + 1, acc}
      {:jmp, offset} -> {pc + offset, acc}
      {:acc, operand} -> {pc + 1, acc + operand}
    end
  end

  def stream(program) do
    Stream.iterate({0, 0}, &execute(program, &1))
  end

  def with_history(stream) do
    Stream.transform(stream, MapSet.new(), &with_history_step/2)
  end

  defp with_history_step({pc, _} = step, history) do
    new_history = MapSet.put(history, pc)
    {[{step, history}], new_history}
  end
end

System.argv()
|> hd()
|> File.stream!()
|> GameConsole.read()
|> GameConsole.stream()
|> GameConsole.with_history()
|> Enum.find(fn {{pc, _}, history} -> MapSet.member?(history, pc) end)
|> IO.inspect(limit: :infinity)


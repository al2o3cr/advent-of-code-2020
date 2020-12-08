defmodule GameConsole do
  def read(stream) do
    stream
    |> Stream.map(&GameConsole.parse/1)
    |> Stream.concat([:halt])
    |> Stream.with_index()
    |> Map.new(fn {v, k} -> {k, v} end)
  end

  def parse(line) do
    [instruction_s, offset_s] = Regex.run(~r/^(nop|jmp|acc) ([+-]\d+)/, line, capture: :all_but_first)

    case {instruction_s, String.to_integer(offset_s)} do
      {"nop", junk} -> {:nop, junk}
      {"jmp", offset} -> {:jmp, offset}
      {"acc", operand} -> {:acc, operand}
    end
  end

  def is_nop?({:nop, _}), do: true
  def is_nop?(_), do: false

  def is_jmp?({:jmp, _}), do: true
  def is_jmp?(_), do: false

  def find_instructions(program, pred) do
    program
    |> Enum.filter(fn {_, v} -> pred.(v) end)
    |> Enum.map(&elem(&1, 0))
  end

  def replace_instruction(program, pc, new_instruction) do
    Map.update!(program, pc, fn {_, v} -> {new_instruction, v} end)
  end

  def execute(_, {:halt, acc}), do: {:halt, acc}

  def execute(program, {pc, acc}) do
    case program[pc] do
      :halt -> {:halt, acc}
      {:nop, _} -> {pc + 1, acc}
      {:jmp, offset} -> {pc + offset, acc}
      {:acc, operand} -> {pc + 1, acc + operand}
    end
  end

  def stream(program) do
    Stream.iterate({0, 0}, &execute(program, &1))
  end

  def check_termination(program) do
    program
    |> stream()
    |> Enum.reduce_while(MapSet.new(), &check_termination_step/2)
  end

  defp check_termination_step({pc, acc}, history) do
    cond do
      pc == :halt -> {:halt, {:halted, acc}}
      MapSet.member?(history, pc) -> {:halt, {:loop, acc}}
      true -> {:cont, MapSet.put(history, pc)}
    end
  end
end

program =
  System.argv()
  |> hd()
  |> File.stream!()
  |> GameConsole.read()

jmp_attempts =
  GameConsole.find_instructions(program, &GameConsole.is_nop?/1)
  |> Enum.map(&{&1, :jmp})

nop_attempts =
  GameConsole.find_instructions(program, &GameConsole.is_jmp?/1)
  |> Enum.map(&{&1, :nop})

Stream.concat(jmp_attempts, nop_attempts)
|> Task.async_stream(fn {pc, op} ->
  GameConsole.replace_instruction(program, pc, op)
  |> GameConsole.check_termination()
end, max_concurrency: 20)
|> Enum.find(fn {:ok, {:halted, _}} -> true; _ -> false end)
|> IO.inspect()

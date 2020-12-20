defmodule SeatMachine do
  use GenStateMachine

  defstruct pos: {0,0}, parent: nil, neighbors: []

  def start_link(args) do
    GenStateMachine.start_link(__MODULE__, args)
  end

  def init({pos, parent}) do
    {:ok, {:empty, -1, {0, 0}}, %SeatMachine{pos: pos, parent: parent}}
  end

  def neighbors(pid, neighbors) do
    GenStateMachine.call(pid, {:neighbors, neighbors})
  end

  def tick(pid) do
    GenStateMachine.cast(pid, {:tick})
  end

  def handle_event({:call, from}, {:neighbors, neighbors}, _state, data) do
    new_data = %{data | neighbors: neighbors}
    {:keep_state, new_data, {:reply, from, :ok}}
  end

  def handle_event(:cast, {:tick}, {:empty, _, {0, 0}} = state, data) do
    {:next_state, next_full(state, data), data, [notify_parent(true), notify_neighbors()]}
  end

  def handle_event(:cast, {:tick}, {:full, _, {n, 0}} = state, data) when n >= 4 do
    {:next_state, next_empty(state, data), data, [notify_parent(true), notify_neighbors()]}
  end

  def handle_event(:cast, {:tick}, {_, _, {_, 0}} = state, data) do
    {:next_state, next_same(state, data), data, [notify_parent(false), notify_neighbors()]}
  end

  def handle_event(:cast, {:tick}, _, _) do
    {:keep_state_and_data, :postpone}
  end

  def handle_event(:cast, {:seat_updated, :full, t}, {status, t2, {taken, waiting}}, data) when t == t2 do
    {:next_state, {status, t2, {taken + 1, waiting - 1}}, data}
  end

  def handle_event(:cast, {:seat_updated, :empty, t}, {status, t2, {taken, waiting}}, data) when t == t2 do
    {:next_state, {status, t2, {taken, waiting - 1}}, data}
  end

  def handle_event(:cast, {:seat_updated, _, t}, {_, t2, _}, _) when t > t2 do
    {:keep_state_and_data, :postpone}
  end

  def handle_event(:internal, {:notify_parent, changed}, {status, t, _}, data) do
    send(data.parent, {:seat_updated, data.pos, status, t, changed})

    :keep_state_and_data
  end

  def handle_event(:internal, {:notify_neighbors}, {status, t, _}, data) do
    data.neighbors
    |> Enum.map(&GenServer.cast(&1, {:seat_updated, status, t}))

    :keep_state_and_data
  end

  defp next_full({_, old_t, _}, data) do
    {:full, old_t + 1, {0, length(data.neighbors)}}
  end

  defp next_empty({_, old_t, _}, data) do
    {:empty, old_t + 1, {0, length(data.neighbors)}}
  end

  defp next_same({status, old_t, _}, data) do
    {status, old_t + 1, {0, length(data.neighbors)}}
  end

  defp notify_parent(updated) do
    {:next_event, :internal, {:notify_parent, updated}}
  end

  defp notify_neighbors() do
    {:next_event, :internal, {:notify_neighbors}}
  end

  def wait(seats) do
    wait(seats, MapSet.new(), false)
  end

  def wait(seats, taken, changed) do
    if MapSet.size(seats) == 0 do
      {taken, changed}
    else
      receive do
        {:seat_updated, pos, :full, _, c} ->
          new_seats = MapSet.delete(seats, pos)
          new_taken = MapSet.put(taken, pos)
          wait(new_seats, new_taken, c or changed)

        {:seat_updated, pos, :empty, _, c} ->
          new_seats = MapSet.delete(seats, pos)
          wait(new_seats, taken, c or changed)
      end
    end
  end
end


defmodule SeatLayout do
  def parse({line, row}) do
    String.split(line, "", trim: true)
    |> Enum.with_index()
    |> Enum.flat_map(fn {"L",col} -> [{row,col}]; {_, _} -> []; end)
  end

  def size(seats) do
    Enum.reduce(seats, {0, 0}, fn {r, c}, {a_r, a_c} -> {max(r, a_r), max(c, a_c)} end)
  end

  def indexes({rows, cols}) do
    for row <- 0..rows, col <- 0..cols, do: {row, col}
  end

  def show(seats, taken, {_rows, cols} = dims) do
    dims
    |> indexes()
    |> Enum.map(&display_pos(seats, taken, &1))
    |> Enum.chunk_every(cols+1)
    |> Enum.map(fn chunk -> [chunk, "\n"] end)
  end

  defp display_pos(seats, taken, pos) do
    cond do
      MapSet.member?(taken, pos) -> "#"
      MapSet.member?(seats, pos) -> "L"
      true -> "."
    end
  end

  def neighbor_indexes({row, col}) do
    [
      {row+1, col+1},
      {row+1, col},
      {row+1, col-1},
      {row, col+1},
      {row, col-1},
      {row-1, col+1},
      {row-1, col},
      {row-1, col-1}
    ]
  end

  def at_neighbors(map, pos) do
    neighbor_indexes(pos)
    |> Enum.flat_map(fn idx ->
      case Map.fetch(map, idx) do
        :error -> []
        {:ok, value} -> [value]
      end
    end)
  end
end

seats =
  System.argv()
  |> hd()
  |> File.stream!()
  |> Stream.with_index()
  |> Stream.flat_map(&SeatLayout.parse/1)
  |> MapSet.new()

dims = SeatLayout.size(seats)

seat_pids =
  seats
  |> Enum.map(&{&1, SeatMachine.start_link({&1, self()})})
  |> Enum.map(fn {k, {:ok, v}} -> {k, v} end)
  |> Map.new()

all_pids = Map.values(seat_pids)

Enum.each(seat_pids, fn {pos, pid} -> SeatMachine.neighbors(pid, SeatLayout.at_neighbors(seat_pids, pos)) end)

Stream.repeatedly(fn ->
  Enum.each(all_pids, &SeatMachine.tick/1)

  SeatMachine.wait(seats)
end)
|> Stream.take_while(&elem(&1, 1))
|> Stream.map(&{elem(&1, 0), SeatLayout.show(seats, elem(&1,0), dims)})
|> Stream.intersperse({:ok, "\u001b[H\u001b[J"})
|> Stream.each(&IO.puts(elem(&1, 1)))
|> Stream.flat_map(fn {:ok, _} -> []; {v, _} -> [v] end)
|> Stream.take(-1)
|> Enum.to_list()
|> hd()
|> MapSet.size()
|> IO.inspect()

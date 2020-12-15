defmodule NumberGame do
  def warmup(list) do
    Enum.reduce(list, {nil, -1, %{}}, &do_warmup/2)
  end

  defp do_warmup(el, {last, prev_idx, seen}) do
    {el, prev_idx+1, Map.put(seen, last, prev_idx)}
  end

  # need index
  def next({last, prev_idx, seen}) do
    idx = prev_idx + 1
    case Map.get(seen, last) do
      nil ->
        {[0], {0, idx, Map.put(seen, last, prev_idx)}}
      seen_prev ->
        new_number = prev_idx - seen_prev
        {[new_number], {new_number, idx, Map.put(seen, last, prev_idx)}}
    end
  end
end

# starting = [0,3,6]
starting = [8,0,17,4,1,12]

resource = Stream.resource(fn -> NumberGame.warmup(starting) end, &NumberGame.next/1, fn _ -> :ok end)

Stream.concat(starting, resource)
|> Stream.drop(29_999_999)
|> Stream.take(1)
|> Enum.to_list()
|> hd()
|> IO.inspect()

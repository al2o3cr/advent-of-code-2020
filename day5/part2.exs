ids = 
  System.argv()
  |> hd()
  |> File.stream!()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.replace(&1, "B", "1"))
  |> Stream.map(&String.replace(&1, "F", "0"))
  |> Stream.map(&String.replace(&1, "R", "1"))
  |> Stream.map(&String.replace(&1, "L", "0"))
  |> Stream.map(&Integer.parse(&1, 2))
  |> Stream.map(&elem(&1, 0))
  |> Enum.sort(:desc)

missing = Enum.to_list(0..hd(ids)) -- ids

missing
|> Enum.max()
|> IO.inspect()

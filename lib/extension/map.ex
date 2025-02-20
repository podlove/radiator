defmodule Extension.Map do
  @moduledoc """
  Safely access a value from a map.
  Won't break if map is nil
  """

  def mget(map, key, default \\ nil)
  def mget(nil, _key, _default), do: nil
  def mget(map, key, default) when is_map(map), do: Map.get(map, key, default)
end

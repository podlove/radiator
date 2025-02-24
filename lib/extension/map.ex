defmodule Extension.Map do
  @moduledoc """
  Safely access a value from a map.
  Won't break if map is nil
  """

  def safe_get(map, key, default \\ nil)
  def safe_get(nil, _key, _default), do: nil
  def safe_get(map, key, default) when is_map(map), do: Map.get(map, key, default)
end
